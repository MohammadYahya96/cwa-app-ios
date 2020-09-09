//
// Created by Hu, Hao on 06.06.20.
// Copyright (c) 2020 SAP SE. All rights reserved.
//

import Foundation
import ExposureNotification

final class ExposureDetectionExecutor: ExposureDetectionDelegate {

	private let client: Client

	private let downloadedPackagesStore: DownloadedPackagesStore
	private let store: Store
	private let exposureDetector: ExposureDetector

	init(
		client: Client,
		downloadedPackagesStore: DownloadedPackagesStore,
		store: Store,
		exposureDetector: ExposureDetector
	) {

		self.client = client
		self.downloadedPackagesStore = downloadedPackagesStore
		self.store = store
		self.exposureDetector = exposureDetector
	}

	#if INTEROP

	func exposureDetection(
		country: String,
		determineAvailableData completion: @escaping (DaysAndHours?, String) -> Void
	) {
		let group = DispatchGroup()

		var daysAndHours = DaysAndHours(days: [], hours: [])
		var errors = [Error]()

		// We only want to download hours in case the hourly fetching mode is enabled.
		// Enabling the hourly fetching mode is only possible for dev/test builds.
		// Unfortunately this mode cannot be enabled in production due to technical limitations
		// regarding the exposure notification framework.
		if store.hourlyFetchingEnabled {
			group.enter()

			client.availableHours(day: .formattedToday(), country: country) { result in
				switch result {
				case let .success(hours):
					daysAndHours.hours = hours
				case let .failure(error):
					errors.append(error)
				}
				group.leave()
			}
		}

		group.enter()

		client.availableDays(forCountry: country) { result in
			switch result {
			case let .success(days):
				daysAndHours.days = days
			case let .failure(error):
				errors.append(error)
			}
			group.leave()
		}

		group.notify(queue: .main) {
			guard errors.isEmpty else {
				logError(
					message: "Unable to determine available data due to errors:\n \(errors.map { $0.localizedDescription }.joined(separator: "\n"))"
				)
				completion(/* we are unable to determine the days and hours */ nil, country)
				return
			}
			completion(daysAndHours, country)
		}
	}

	func exposureDetection(
		country: String,
		downloadDeltaFor remote: DaysAndHours
	) -> DaysAndHours {

		// prune the store
		try? downloadedPackagesStore.deleteOutdatedDays(now: .formattedToday())

		let localDays = Set(downloadedPackagesStore.allDays(country: country))
		let localHours = Set(downloadedPackagesStore.hours(for: .formattedToday(), country: country))

		let delta = DeltaCalculationResult(
			remoteDays: Set(remote.days),
			remoteHours: Set(remote.hours),
			localDays: localDays,
			localHours: localHours
		)

		return DaysAndHours(
			days: Array(delta.missingDays),
			hours: Array(delta.missingHours)
		)
	}

	func exposureDetection(
		country: String,
		downloadAndStore delta: DaysAndHours,
		completion: @escaping (Error?) -> Void
	) {
		func storeDaysAndHours(_ fetchedDaysAndHours: FetchedDaysAndHours) {
			downloadedPackagesStore.addFetchedDaysAndHours(fetchedDaysAndHours, country: country)
			completion(nil)
		}

		client.fetchDays(
				delta.days,
				hours: delta.hours,
				of: .formattedToday(),
				country: country,
				completion: storeDaysAndHours
		)
	}

	func exposureDetectionWriteDownloadedPackages(
		country: String
	) -> WrittenPackages? {

		let fileManager = FileManager()
		let rootDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		do {
			try fileManager.createDirectory(at: rootDir, withIntermediateDirectories: true, attributes: nil)

			let writer = AppleFilesWriter(rootDir: rootDir)

			if store.hourlyFetchingEnabled {
				let hourlyPackages = downloadedPackagesStore.hourlyPackages(for: .formattedToday(), country: country)
				for keyPackage in hourlyPackages {
					let success = writer.writePackage(keyPackage)
					if !success {
						return nil
					}
				}
			} else {
				let allDays = downloadedPackagesStore.allDays(country: country)

				for day in allDays {
					let _keyPackage = autoreleasepool(invoking: { downloadedPackagesStore.package(for: day, country: country) })
					if let keyPackage = _keyPackage {
						let success = writer.writePackage(keyPackage)
						if !success {
							return nil
						}
					}
				}
			}
			return writer.writtenPackages
		} catch {
			return nil
		}
	}

	func exposureDetection(
		country: String,
		downloadConfiguration completion: @escaping (ENExposureConfiguration?, String) -> Void
	) {
		client.exposureConfiguration(country: country, completion: completion)
	}

	#else

	func exposureDetection(
		_ detection: ExposureDetection,
		determineAvailableData completion: @escaping (DaysAndHours?) -> Void
	) {
		let group = DispatchGroup()

		var daysAndHours = DaysAndHours(days: [], hours: [])
		var errors = [Error]()

		// We only want to download hours in case the hourly fetching mode is enabled.
		// Enabling the hourly fetching mode is only possible for dev/test builds.
		// Unfortunately this mode cannot be enabled in production due to technical limitations
		// regarding the exposure notification framework.
		if store.hourlyFetchingEnabled {
			group.enter()

			client.availableHours(day: .formattedToday()) { result in
				switch result {
				case let .success(hours):
					daysAndHours.hours = hours
				case let .failure(error):
					errors.append(error)
				}
				group.leave()
			}
		}

		group.enter()

		client.availableDays { result in
			switch result {
			case let .success(days):
				daysAndHours.days = days
			case let .failure(error):
				errors.append(error)
			}
			group.leave()
		}

		group.notify(queue: .main) {
			guard errors.isEmpty else {
				logError(
					message: "Unable to determine available data due to errors:\n \(errors.map { $0.localizedDescription }.joined(separator: "\n"))"
				)
				completion(/* we are unable to determine the days and hours */ nil)
				return
			}
			completion(daysAndHours)
		}
	}

	func exposureDetection(
		_ detection: ExposureDetection,
		downloadDeltaFor remote: DaysAndHours
	) -> DaysAndHours {

		// prune the store
		try? downloadedPackagesStore.deleteOutdatedDays(now: .formattedToday())

		let localDays = Set(downloadedPackagesStore.allDays())
		let localHours = Set(downloadedPackagesStore.hours(for: .formattedToday()))

		let delta = DeltaCalculationResult(
			remoteDays: Set(remote.days),
			remoteHours: Set(remote.hours),
			localDays: localDays,
			localHours: localHours
		)

		return DaysAndHours(
			days: Array(delta.missingDays),
			hours: Array(delta.missingHours)
		)
	}

	func exposureDetection(
		_ detection: ExposureDetection,
		downloadAndStore delta: DaysAndHours,
		completion: @escaping (Error?) -> Void
	) {
		func storeDaysAndHours(_ fetchedDaysAndHours: FetchedDaysAndHours) {
			downloadedPackagesStore.addFetchedDaysAndHours(fetchedDaysAndHours)
			completion(nil)
		}

		client.fetchDays(
				delta.days,
				hours: delta.hours,
				of: .formattedToday(),
				completion: storeDaysAndHours
		)
	}

	func exposureDetectionWriteDownloadedPackages(_ detection: ExposureDetection) -> WrittenPackages? {
		let fileManager = FileManager()
		let rootDir = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
		do {
			try fileManager.createDirectory(at: rootDir, withIntermediateDirectories: true, attributes: nil)

			let writer = AppleFilesWriter(rootDir: rootDir)

			if store.hourlyFetchingEnabled {
				let hourlyPackages = downloadedPackagesStore.hourlyPackages(for: .formattedToday())
				for keyPackage in hourlyPackages {
					let success = writer.writePackage(keyPackage)
					if !success {
						return nil
					}
				}
			} else {
				let allDays = downloadedPackagesStore.allDays()
				for day in allDays {
					let _keyPackage = autoreleasepool(invoking: { downloadedPackagesStore.package(for: day) })
					if let keyPackage = _keyPackage {
						let success = writer.writePackage(keyPackage)
						if !success {
							return nil
						}
					}
				}
			}
			return writer.writtenPackages
		} catch {
			return nil
		}
	}

	func exposureDetection(
		_ detection: ExposureDetection,
		downloadConfiguration completion: @escaping (ENExposureConfiguration?) -> Void
	) {
		client.exposureConfiguration(completion: completion)
	}

	#endif

	func exposureDetection(
			_ detection: ExposureDetection,
			detectSummaryWithConfiguration configuration: ENExposureConfiguration,
			writtenPackages: WrittenPackages,
			completion: @escaping (Result<ENExposureDetectionSummary, Error>) -> Void
	) -> Progress {
		func withResultFrom(
				summary: ENExposureDetectionSummary?,
				error: Error?
		) -> Result<ENExposureDetectionSummary, Error> {
			if let error = error {
				return .failure(error)
			}
			if let summary = summary {
				return .success(summary)
			}
			fatalError("invalid state")
		}
		return exposureDetector.detectExposures(
				configuration: configuration,
				diagnosisKeyURLs: writtenPackages.urls
		) { summary, error in
			completion(withResultFrom(summary: summary, error: error))
		}
	}
}

extension DownloadedPackagesStore {

	#if INTEROP

	func addFetchedDaysAndHours(_ daysAndHours: FetchedDaysAndHours, country: String) {
		let days = daysAndHours.days
		days.bucketsByDay.forEach { day, bucket in
			self.set(country: country, day: day, package: bucket)
		}

		let hours = daysAndHours.hours
		hours.bucketsByHour.forEach { hour, bucket in
			self.set(country: country, hour: hour, day: hours.day, package: bucket)
		}
	}

	#else

	func addFetchedDaysAndHours(_ daysAndHours: FetchedDaysAndHours) {
		let days = daysAndHours.days
		days.bucketsByDay.forEach { day, bucket in
			self.set(day: day, package: bucket)
		}

		let hours = daysAndHours.hours
		hours.bucketsByHour.forEach { hour, bucket in
			self.set(hour: hour, day: hours.day, package: bucket)
		}
	}

	#endif
}
