//
//  ViewController.swift
//  github-search-app
//
//  Created by jun.ogino on 2024/04/26.
//

import UIKit
import Combine

final class RepositoryCell: UICollectionViewCell {

    private lazy var repositoryNameLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    private lazy var descriptionNameLabel: UILabel = {
        let label = UILabel()
        return label
    }()

    func configure(with model: RepositoryForView) {
        repositoryNameLabel.text = model.name
        descriptionNameLabel.text = model.htmlUrl
    }

    override init(frame: CGRect) {
        super.init(frame: .zero)
        self.contentView.addSubview(repositoryNameLabel)
        self.contentView.addSubview(descriptionNameLabel)
        repositoryNameLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionNameLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            repositoryNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            repositoryNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            repositoryNameLabel.heightAnchor.constraint(equalToConstant: 30),
            repositoryNameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            descriptionNameLabel.topAnchor.constraint(equalTo: repositoryNameLabel.bottomAnchor, constant: 20),
            descriptionNameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            descriptionNameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            descriptionNameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20)
        ])
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct RepositoryForView {
    let name: String
    let htmlUrl: String
}

public struct RepositoryCellModel {
    var items: [RepositoryForView]?

    init(model: GitHubRepositories) {
        self.items = model.items?.map {
            .init(name: $0.name, htmlUrl: $0.htmlUrl)
        }
    }
}

class ViewController: UIViewController {

    var searchBar: UISearchBar = {
        let field = UISearchBar()
        field.backgroundColor = .red
        return field
    }()

    var searchWord: String?

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = .init(width: 300, height: 100)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.dataSource = self
        collectionView.backgroundColor = .white
        return collectionView
    }()

    let registration = UICollectionView.CellRegistration<RepositoryCell, RepositoryForView>() { cell, indexPath, repository in
        cell.configure(with: repository)
        cell.backgroundColor = .yellow
    }

    private var repository: [RepositoryForView] = [] {
        didSet {
            DispatchQueue.main.sync {
                self.collectionView.reloadData()
            }
        }
    }

    var collectionViewCell: UICollectionViewCell = {
        let cell = UICollectionViewCell()
        return cell
    }()

    lazy var searchButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .red
        button.addAction(.init { [weak self] _ in
            self?.search()
        }, for: .touchUpInside)
        return button
    }()

    func search() {
        let request = GitHubSearchRepositoriesAPIRequest(searchWord: self.searchWord ?? "")
        APIClient().request(request) { result in
            switch(result) {
            case let .success(model):
                self.repository = []
                guard let items = model?.items else { return }
                items.forEach { item in
                    self.repository.append(.init(name: item.name, htmlUrl: item.htmlUrl))
                }
            case let .failure(error):
                switch error {
                case let .server(status):
                    print("error: \(status)")
                case .noResponse:
                    print("no response")
                case let .unknown(e):
                    print("error: \(e)")
                default:
                    print("error: \(error)")
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .white
        view.addSubview(searchBar)
        view.addSubview(collectionView)
        view.addSubview(searchButton)

        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.backgroundColor = .clear
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        searchButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            searchBar.trailingAnchor.constraint(equalTo: searchButton.trailingAnchor, constant: -20),
            searchBar.heightAnchor.constraint(equalToConstant: 30),
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            searchButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            searchButton.widthAnchor.constraint(equalToConstant: 30),
            searchButton.heightAnchor.constraint(equalToConstant: 30),
            searchButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 20),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])

        collectionView.delegate = self
        collectionView.dataSource = self
        searchBar.delegate = self
    }
}

extension ViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        print("didChange")
        searchWord = searchText
    }
}

extension ViewController: UICollectionViewDelegate {
    
}

extension ViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return repository.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        collectionView.dequeueConfiguredReusableCell(using: registration, for: indexPath, item: repository[indexPath.item])
    }
}

