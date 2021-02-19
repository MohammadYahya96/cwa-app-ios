////
// 🦠 Corona-Warn-App
//

import Foundation

typealias Analytics = PPAnalyticsCollector

/// Singleton to collect the analytics dataand to save it in the database, to load it from the database, to remove every analytics data from the store. This also triggers a submission.
enum PPAnalyticsCollector {

	// MARK: - Internal

	/// Setup Analytics for regular use
	static func setup(
		store: Store,
		submitter: PPAnalyticsSubmitter
	) {
		PPAnalyticsCollector.store = store
		PPAnalyticsCollector.submitter = submitter
	}

	/// Setup Analytics for testing.
	static func setupMock(
		store: Store? = nil,
		submitter: PPAnalyticsSubmitter? = nil
	) {
		PPAnalyticsCollector.store = store
		PPAnalyticsCollector.submitter = submitter
	}

	static func log(_ dataType: PPADataType) {
		switch dataType {
		case let .userData(userMetadata):
			Analytics.logUserMetadata(userMetadata)
		case let .riskExposureMetadata(riskExposureMetadata):
			Analytics.logRiskExposureMetadata(riskExposureMetadata)
		case let .clientMetadata(clientMetadata):
			Analytics.logClientMetadata(clientMetadata)
		case let .testResultMetadata(testResultMetaData):
			Analytics.logTestResultMetadata(testResultMetaData)
		case let .keySubmissionMetadata(keySubmissionMetadata):
			Analytics.logKeySubmissionMetadata(keySubmissionMetadata)
		}

		Analytics.triggerAnalyticsSubmission()
	}

	static func deleteAnalyticsData() {
		store?.currentRiskExposureMetadata = nil
		store?.previousRiskExposureMetadata = nil
		store?.userMetadata = nil
		store?.lastSubmittedPPAData = nil
		store?.lastAppReset = nil
		store?.lastSubmissionAnalytics = nil
		store?.clientMetadata = nil
		store?.testResultMetadata = nil
		store?.keySubmissionMetadata = nil
		Log.info("Deleted all analytics data in the store", log: .ppa)
	}

	static func triggerAnalyticsSubmission() {
		guard let submitter = submitter else {
			Log.warning("I cannot submit analytics data. Perhaps i am a mock or setup was not called correctly?", log: .ppa)
			return
		}
		submitter.triggerSubmitData()
	}

	// MARK: - Private

	private static var _store: Store?

	// wrapper property to add a log when the value is nil
	private static var store: Store? {
		get {
			if _store == nil {
				Log.warning("I cannot log analytics data. Perhaps i am a mock or setup was not called correctly?", log: .ppa)
			}
			return _store
		}
		set {
			_store = newValue
		}
	}

	private static var submitter: PPAnalyticsSubmitter?

	// MARK: - UserMetada

	private static func logUserMetadata(_ userMetadata: PPAUserMetadata) {
		switch userMetadata {
		case let .complete(metaData):
			store?.userMetadata = metaData
		}
	}

	// MARK: - RiskExposureMetadata

	private static func logRiskExposureMetadata(_ riskExposureMetadata: PPARiskExposureMetadata) {
		switch riskExposureMetadata {
		case let .complete(metaData):
			store?.currentRiskExposureMetadata = metaData
		}
	}

	// MARK: - ClientMetadata

	private static func logClientMetadata(_ clientMetadata: PPAClientMetadata) {
		switch clientMetadata {
		case let .complete(metaData):
			store?.clientMetadata = metaData
		case let .eTag(etag):
			store?.clientMetadata?.eTag = etag
		}
	}

	// MARK: - TestResultMetadata

	private static func logTestResultMetadata(_ testResultMetadata: PPATestResultMetadata) {
		switch testResultMetadata {
		case let .complete(metaData):
			store?.testResultMetadata = metaData
		case let .testResult(testResult):
			store?.testResultMetadata?.testResult = testResult
		case let .testResultHoursSinceTestRegistration(hoursSinceTestRegistration):
			store?.testResultMetadata?.hoursSinceTestRegistration = hoursSinceTestRegistration
		case let .updateTestResult(testResult):
			Analytics.updateTestResult(testResult)
		}
	}

	private static func updateTestResult(_ testResult: TestResult) {
		// we only save metadata for tests submitted on QR code,and there is the only place in the app where we set the registration date
		guard store?.testResultMetadata?.testRegistrationDate != nil else {
			return
		}

		let storedTestResult = store?.testResultMetadata?.testResult
		// if storedTestResult != newTestResult ---> update persisted testResult and the hoursSinceTestRegistration
		// if storedTestResult == nil ---> update persisted testResult and the hoursSinceTestRegistration
		// if storedTestResult == newTestResult ---> do nothing

		if storedTestResult == nil || storedTestResult != testResult {
			switch testResult {
			case .positive, .negative, .pending:
				Analytics.log(.testResultMetadata(.testResult(testResult)))

				guard let registrationDate = store?.testResultMetadata?.testRegistrationDate else {
					return
				}

				switch store?.testResultMetadata?.testResult {
				case .positive, .negative, .pending:
					let diffComponents = Calendar.current.dateComponents([.hour], from: registrationDate, to: Date())
					Analytics.log(.testResultMetadata(.testResultHoursSinceTestRegistration(diffComponents.hour)))
				default:
					Analytics.log(.testResultMetadata(.testResultHoursSinceTestRegistration(nil)))
				}

			case .expired, .invalid:
				break
			}
		}
	}

	// MARK: - KeySubmissionMetadata


	// swiftlint:disable:next cyclomatic_complexity
	private static func logKeySubmissionMetadata(_ keySubmissionMetadata: PPAKeySubmissionMetadata) {
		switch keySubmissionMetadata {
		case let .complete(metadata):
			store?.keySubmissionMetadata = metadata
		case let .submitted(submitted):
			store?.keySubmissionMetadata?.submitted = submitted
		case let .submittedInBackground(inBackground):
			store?.keySubmissionMetadata?.submittedInBackground = inBackground
		case let .submittedAfterCancel(afterCancel):
			store?.keySubmissionMetadata?.submittedAfterCancel = afterCancel
		case let .submittedAfterSymptomFlow(afterSymptomFlow):
			store?.keySubmissionMetadata?.submittedAfterSymptomFlow = afterSymptomFlow
		case let .submittedWithTeletan(withTeletan):
			store?.keySubmissionMetadata?.submittedWithTeleTAN = withTeletan
		case let .lastSubmissionFlowScreen(flowScreen):
			store?.keySubmissionMetadata?.lastSubmissionFlowScreen = flowScreen
		case let .advancedConsentGiven(advanced):
			store?.keySubmissionMetadata?.advancedConsentGiven = advanced
		case let .hoursSinceTestResult(hours):
			store?.keySubmissionMetadata?.hoursSinceTestResult = hours
		case let .keySubmissionHoursSinceTestRegistration(hours):
			store?.keySubmissionMetadata?.hoursSinceTestRegistration = hours
		case let .daysSinceMostRecentDateAtRiskLevelAtTestRegistration(date):
			store?.keySubmissionMetadata?.daysSinceMostRecentDateAtRiskLevelAtTestRegistration = date
		case let .hoursSinceHighRiskWarningAtTestRegistration(hours):
			store?.keySubmissionMetadata?.hoursSinceHighRiskWarningAtTestRegistration = hours
		case .setHoursSinceTestResult:
			Analytics.setHoursSinceTestResult()
		case .setHoursSinceTestRegistration:
			Analytics.setHoursSinceTestResult()
		case .setHoursSinceHighRiskWarningAtTestRegistration:
			Analytics.setHoursSinceHighRiskWarningAtTestRegistration()
		case .setDaysSinceMostRecentDateAtRiskLevelAtTestRegistration:
			Analytics.setDaysSinceMostRecentDateAtRiskLevelAtTestRegistration()
		}
	}

	private static func setHoursSinceTestResult() {
		guard let resultDateTimeStamp = store?.testResultReceivedTimeStamp else {
			return
		}

		let timeInterval = TimeInterval(resultDateTimeStamp)
		let resultDate = Date(timeIntervalSince1970: timeInterval)
		let diffComponents = Calendar.current.dateComponents([.hour], from: resultDate, to: Date())
		store?.keySubmissionMetadata?.hoursSinceTestResult = Int32(diffComponents.hour ?? 0)
	}

	private static func setHoursSinceTestRegistration() {
		guard let registrationDate = store?.testRegistrationDate else {
			return
		}

		let diffComponents = Calendar.current.dateComponents([.hour], from: registrationDate, to: Date())
		store?.keySubmissionMetadata?.hoursSinceTestRegistration = Int32(diffComponents.hour ?? 0)
	}

	private static func setDaysSinceMostRecentDateAtRiskLevelAtTestRegistration() {
		guard let numberOfDaysWithCurrentRiskLevel = store?.riskCalculationResult?.numberOfDaysWithCurrentRiskLevel  else {
			return
		}
		store?.keySubmissionMetadata?.daysSinceMostRecentDateAtRiskLevelAtTestRegistration = Int32(numberOfDaysWithCurrentRiskLevel)
	}

	private static func setHoursSinceHighRiskWarningAtTestRegistration() {
		guard let riskLevel = store?.riskCalculationResult?.riskLevel  else {
			return
		}
		switch riskLevel {
		case .high:
			guard let timeOfRiskChangeToHigh = store?.dateOfConversionToHighRisk,
				  let registrationTime = store?.testRegistrationDate else {
				Log.debug("Time of risk status change was not stored correctly.")
				return
			}
			let differenceInHours = Calendar.current.dateComponents([.hour], from: timeOfRiskChangeToHigh, to: registrationTime)
			store?.keySubmissionMetadata?.hoursSinceHighRiskWarningAtTestRegistration = Int32(differenceInHours.hour ?? -1)
		case .low:
			store?.keySubmissionMetadata?.hoursSinceHighRiskWarningAtTestRegistration = -1
		}
	}
}
