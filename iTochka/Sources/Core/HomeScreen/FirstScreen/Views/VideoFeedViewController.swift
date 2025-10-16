//
//  VideoFeedViewController.swift
//  iTochka
//
//  Created by Fedor Donskov on 16.10.2025.
//

import UIKit

// MARK: - VideoFeedViewController
final class VideoFeedViewController: UIViewController,
    UICollectionViewDataSource, UICollectionViewDelegate,
    UICollectionViewDataSourcePrefetching, UIScrollViewDelegate {

    var onVideoTapped: ((VideoItem) -> Void)?

    private let service = VideoService()
    private var items: [VideoItem] = []
    private var total = 0
    private var isLoading = false
    private var offset = 0
    private let limit = 10

    private var collectionView: UICollectionView!
    private var layout: UICollectionViewFlowLayout!

    private let horizontalPadding: CGFloat = 16
    private let lineSpacing: CGFloat = 26
    private let peekVisible: CGFloat = 80

    private var itemHeight: CGFloat = 0
    private var sectionInsetTopBottom: CGFloat = 0
    private var didCenterFirst = false

    static var isSoundEnabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.clipsToBounds = false
        configureCollectionView()
        loadInitial()
    }

    private func configureCollectionView() {
        layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = lineSpacing
        layout.minimumInteritemSpacing = 0

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .black
        collectionView.isPagingEnabled = false
        collectionView.decelerationRate = .fast
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.clipsToBounds = false

        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.register(VideoFeedCell.self, forCellWithReuseIdentifier: VideoFeedCell.reuseID)

        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        let bounds = collectionView.bounds
        let oldHeight = itemHeight

        sectionInsetTopBottom = peekVisible
        itemHeight = bounds.height - (peekVisible * 2)

        layout.itemSize = CGSize(width: bounds.width - horizontalPadding * 2,
                                 height: itemHeight)
        layout.sectionInset = UIEdgeInsets(top: sectionInsetTopBottom,
                                           left: horizontalPadding,
                                           bottom: sectionInsetTopBottom,
                                           right: horizontalPadding)
        layout.minimumLineSpacing = lineSpacing
        layout.invalidateLayout()

        if !didCenterFirst, !items.isEmpty, oldHeight == 0, itemHeight > 0 {
            centerFirstItemIfNeeded()
        }
    }

    private func loadInitial() {
        guard !isLoading else { return }
        isLoading = true

        Task { [weak self] in
            guard let self else { return }
            do {
                let resp = try await service.fetchVideos(offset: 0, limit: limit)
                await MainActor.run {
                    self.items = resp.items
                    self.total = resp.total
                    self.offset = resp.items.count
                    self.collectionView.reloadData()
                    self.isLoading = false

                    self.collectionView.layoutIfNeeded()

                    if self.itemHeight > 0, !self.didCenterFirst {
                        self.centerFirstItemIfNeeded()
                    }
                }
            } catch {
                await MainActor.run { self.isLoading = false }
                print("Load error:", error)
            }
        }
    }

    private func centerFirstItemIfNeeded() {
        guard !didCenterFirst, !items.isEmpty, itemHeight > 0 else {
            return
        }

        didCenterFirst = true

        let initialOffset = targetOffsetY(for: 0)
        collectionView.setContentOffset(CGPoint(x: 0, y: initialOffset), animated: false)
        collectionView.layoutIfNeeded()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self else { return }
            self.playCenteredCell()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self else { return }
            self.playCenteredCell()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self else { return }
            self.playCenteredCell()
        }
    }

    private func loadMoreIfNeeded(nextIndex: Int) {
        guard nextIndex >= items.count - 4, items.count < total, !isLoading else { return }
        isLoading = true
        Task { [weak self] in
            guard let self else { return }
            do {
                let resp = try await service.fetchVideos(offset: self.offset, limit: self.limit)
                await MainActor.run {
                    let start = self.items.count
                    self.items.append(contentsOf: resp.items)
                    self.offset += resp.items.count
                    self.collectionView.performBatchUpdates {
                        let new = (start..<self.items.count).map { IndexPath(item: $0, section: 0) }
                        self.collectionView.insertItems(at: new)
                    }
                    self.isLoading = false
                }
            } catch {
                await MainActor.run { self.isLoading = false }
                print("Pagination error:", error)
            }
        }
    }

    // MARK: - UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: VideoFeedCell.reuseID, for: indexPath) as! VideoFeedCell
        cell.configure(with: items[indexPath.item])

        cell.onPhotoTimeElapsed = { [weak self] in
            guard let self else { return }
            if self.centeredIndexPath() == indexPath {
                self.scrollTo(index: indexPath.item + 1)
            }
        }

        cell.onTap = { [weak self] in
            guard let self else { return }
            let item = self.items[indexPath.item]
            self.onVideoTapped?(item)
        }

        return cell
    }

    // MARK: - Prefetch
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        guard let max = indexPaths.map(\.item).max() else { return }
        loadMoreIfNeeded(nextIndex: max)
    }

    private var groupStep: CGFloat { itemHeight + lineSpacing }

    private func targetOffsetY(for index: Int) -> CGFloat {
        let bounds = collectionView.bounds
        let midItem = sectionInsetTopBottom + CGFloat(index) * groupStep + itemHeight / 2
        return midItem - bounds.height / 2
    }

    private func nearestIndex(to contentOffsetY: CGFloat) -> Int {
        let bounds = collectionView.bounds
        let screenMid = contentOffsetY + bounds.height / 2
        let zeroMid = sectionInsetTopBottom + itemHeight / 2
        let raw = (screenMid - zeroMid) / groupStep
        let idx = Int(raw.rounded())
        return max(0, min(idx, items.count - 1))
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {

        let proposedY = targetContentOffset.pointee.y
        var index = nearestIndex(to: proposedY)

        if abs(velocity.y) > 0.35 {
            index += (velocity.y > 0) ? 1 : -1
            index = max(0, min(index, items.count - 1))
        }

        targetContentOffset.pointee.y = targetOffsetY(for: index)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
            guard let self else { return }
            self.playCenteredCell()
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        playCenteredCell()
    }

    private func centeredIndexPath() -> IndexPath? {
        let idx = nearestIndex(to: collectionView.contentOffset.y)
        return IndexPath(item: idx, section: 0)
    }

    func playCenteredCell() {
        guard let ip = centeredIndexPath() else {
            return
        }

        collectionView.visibleCells.forEach { cell in
            guard let videoCell = cell as? VideoFeedCell else { return }
            let cellIndex = collectionView.indexPath(for: cell)
            if cellIndex != ip {
                videoCell.stopPlayback()
            }
        }

        if let cell = collectionView.cellForItem(at: ip) as? VideoFeedCell {
            cell.playWithSound()
        } else {

        }
    }

    private func scrollTo(index: Int) {
        guard index < items.count else { return }
        let group = itemHeight + lineSpacing
        let y = CGFloat(index) * group - collectionView.contentInset.top + sectionInsetTopBottom
        collectionView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
    }

    func stopAllPlayback() {
        collectionView.visibleCells.forEach { cell in
            (cell as? VideoFeedCell)?.stopPlayback()
        }
    }
}
