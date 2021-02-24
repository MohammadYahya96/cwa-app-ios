//
// 🦠 Corona-Warn-App
//

@testable import ENA
import XCTest

class KeySubmissionMetadataServiceTests: XCTestCase {
	
	func testKeySubmissionMetadataValues_HighRisk() {
		let secureStore = MockTestStore()
		let riskCalculationResult = mockHighRiskCalculationResult()
		let isSubmissionConsentGiven = true
		secureStore.dateOfConversionToHighRisk = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.riskCalculationResult = riskCalculationResult
		secureStore.testRegistrationDate = Date()

		let keySubmissionService = KeySubmissionService(store: secureStore)
		secureStore.keySubmissionMetadata = KeySubmissionMetadata(submitted: false, submittedInBackground: false, submittedAfterCancel: false, submittedAfterSymptomFlow: false, lastSubmissionFlowScreen: .submissionFlowScreenUnknown, advancedConsentGiven: isSubmissionConsentGiven, hoursSinceTestResult: 0, hoursSinceTestRegistration: 0, daysSinceMostRecentDateAtRiskLevelAtTestRegistration: -1, hoursSinceHighRiskWarningAtTestRegistration: -1, submittedWithTeleTAN: true)
		keySubmissionService.setDaysSinceMostRecentDateAtRiskLevelAtTestRegistration()
		keySubmissionService.setHoursSinceHighRiskWarningAtTestRegistration()

		XCTAssertNotNil(secureStore.keySubmissionMetadata, "keySubmissionMetadata should be initialized with default values")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.daysSinceMostRecentDateAtRiskLevelAtTestRegistration, Int32(riskCalculationResult.numberOfDaysWithCurrentRiskLevel), "number of days should be same")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.hoursSinceHighRiskWarningAtTestRegistration, 24, "the difference is one day so it should be 24")
	}

	func testKeySubmissionMetadataValues_HighRisk_testHours() {
		let secureStore = MockTestStore()
		let riskCalculationResult = mockHighRiskCalculationResult()
		let isSubmissionConsentGiven = true
		let dateSixHourAgo = Calendar.current.date(byAdding: .hour, value: -6, to: Date())
		secureStore.dateOfConversionToHighRisk = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.riskCalculationResult = riskCalculationResult
		secureStore.testRegistrationDate = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.testResultReceivedTimeStamp = Int64(dateSixHourAgo?.timeIntervalSince1970 ?? Date().timeIntervalSince1970)

		let keySubmissionService = KeySubmissionService(store: secureStore)
		secureStore.keySubmissionMetadata = KeySubmissionMetadata(submitted: false, submittedInBackground: false, submittedAfterCancel: false, submittedAfterSymptomFlow: false, lastSubmissionFlowScreen: .submissionFlowScreenUnknown, advancedConsentGiven: isSubmissionConsentGiven, hoursSinceTestResult: 0, hoursSinceTestRegistration: 0, daysSinceMostRecentDateAtRiskLevelAtTestRegistration: -1, hoursSinceHighRiskWarningAtTestRegistration: -1, submittedWithTeleTAN: true)
		keySubmissionService.setHoursSinceTestRegistration()
		keySubmissionService.setHoursSinceTestResult()

		XCTAssertNotNil(secureStore.keySubmissionMetadata, "keySubmissionMetadata should be initialized with default values")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.hoursSinceTestResult, 6, "number of hours should be 6")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.hoursSinceTestRegistration, 24, "the difference is one day so it should be 24")
	}

	func testKeySubmissionMetadataValues_HighRisk_submittedInBackground() {
		let secureStore = MockTestStore()
		let riskCalculationResult = mockHighRiskCalculationResult()
		let isSubmissionConsentGiven = true
		secureStore.dateOfConversionToHighRisk = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.riskCalculationResult = riskCalculationResult

		let keySubmissionService = KeySubmissionService(store: secureStore)
		secureStore.keySubmissionMetadata = KeySubmissionMetadata(submitted: false, submittedInBackground: false, submittedAfterCancel: false, submittedAfterSymptomFlow: false, lastSubmissionFlowScreen: .submissionFlowScreenUnknown, advancedConsentGiven: isSubmissionConsentGiven, hoursSinceTestResult: 0, hoursSinceTestRegistration: 0, daysSinceMostRecentDateAtRiskLevelAtTestRegistration: -1, hoursSinceHighRiskWarningAtTestRegistration: -1, submittedWithTeleTAN: true)
		
		keySubmissionService.setSubmitted(withValue: true)
		keySubmissionService.setSubmittedInBackground(withValue: true)


		XCTAssertNotNil(secureStore.keySubmissionMetadata, "keySubmissionMetadata should be initialized with default values")
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submitted) != false))
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submittedInBackground) != false))
	}

	func testKeySubmissionMetadataValues_HighRisk_testSubmitted() {
		let secureStore = MockTestStore()
		let riskCalculationResult = mockHighRiskCalculationResult()
		let isSubmissionConsentGiven = true
		secureStore.dateOfConversionToHighRisk = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.riskCalculationResult = riskCalculationResult

		let keySubmissionService = KeySubmissionService(store: secureStore)
		secureStore.keySubmissionMetadata = KeySubmissionMetadata(submitted: false, submittedInBackground: false, submittedAfterCancel: false, submittedAfterSymptomFlow: false, lastSubmissionFlowScreen: .submissionFlowScreenUnknown, advancedConsentGiven: isSubmissionConsentGiven, hoursSinceTestResult: 0, hoursSinceTestRegistration: 0, daysSinceMostRecentDateAtRiskLevelAtTestRegistration: -1, hoursSinceHighRiskWarningAtTestRegistration: -1, submittedWithTeleTAN: true)
		
		keySubmissionService.setSubmitted(withValue: true)
		keySubmissionService.setSubmittedInBackground(withValue: false)
		keySubmissionService.setSubmittedAfterCancel(withValue: true)
		keySubmissionService.setSubmittedAfterSymptomFlow(withValue: true)
		keySubmissionService.setLastSubmissionFlowScreen(withValue: .submissionFlowScreenSymptoms)
		keySubmissionService.setSubmittedWithTeleTAN(withValue: true)

		XCTAssertNotNil(secureStore.keySubmissionMetadata, "keySubmissionMetadata should be initialized with default values")
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submitted) != false))
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submittedInBackground) != true))
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submittedAfterCancel) != false))
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submittedAfterSymptomFlow) != false))
		XCTAssertEqual(secureStore.keySubmissionMetadata?.lastSubmissionFlowScreen, .submissionFlowScreenSymptoms)
		XCTAssertTrue(((secureStore.keySubmissionMetadata?.submittedWithTeleTAN) != false))
	}

	func testKeySubmissionMetadataValues_LowRisk() {
		let secureStore = MockTestStore()
		let riskCalculationResult = mockLowRiskCalculationResult()
		let isSubmissionConsentGiven = true
		secureStore.dateOfConversionToHighRisk = Calendar.current.date(byAdding: .day, value: -1, to: Date())
		secureStore.riskCalculationResult = riskCalculationResult
		secureStore.testRegistrationDate = Date()

		let keySubmissionService = KeySubmissionService(store: secureStore)
		secureStore.keySubmissionMetadata = KeySubmissionMetadata(submitted: false, submittedInBackground: false, submittedAfterCancel: false, submittedAfterSymptomFlow: false, lastSubmissionFlowScreen: .submissionFlowScreenUnknown, advancedConsentGiven: isSubmissionConsentGiven, hoursSinceTestResult: 0, hoursSinceTestRegistration: 0, daysSinceMostRecentDateAtRiskLevelAtTestRegistration: -1, hoursSinceHighRiskWarningAtTestRegistration: -1, submittedWithTeleTAN: true)
		keySubmissionService.setDaysSinceMostRecentDateAtRiskLevelAtTestRegistration()
		keySubmissionService.setHoursSinceHighRiskWarningAtTestRegistration()

		XCTAssertNotNil(secureStore.keySubmissionMetadata, "keySubmissionMetadata should be initialized with default values")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.daysSinceMostRecentDateAtRiskLevelAtTestRegistration, Int32(riskCalculationResult.numberOfDaysWithCurrentRiskLevel), "number of days should be same")
		XCTAssertEqual(secureStore.keySubmissionMetadata?.hoursSinceHighRiskWarningAtTestRegistration, -1, "the value should be default value i.e., -1 as the risk is low")
	}

	private func mockHighRiskCalculationResult(risk: RiskLevel = .high) -> RiskCalculationResult {
		RiskCalculationResult(
			riskLevel: risk,
			minimumDistinctEncountersWithLowRisk: 0,
			minimumDistinctEncountersWithHighRisk: 0,
			mostRecentDateWithLowRisk: Date(),
			mostRecentDateWithHighRisk: Date(),
			numberOfDaysWithLowRisk: 0,
			numberOfDaysWithHighRisk: 2,
			calculationDate: Date(),
			riskLevelPerDate: [:],
			minimumDistinctEncountersWithHighRiskPerDate: [:]
		)
	}
	private func mockLowRiskCalculationResult(risk: RiskLevel = .low) -> RiskCalculationResult {
		RiskCalculationResult(
			riskLevel: risk,
			minimumDistinctEncountersWithLowRisk: 0,
			minimumDistinctEncountersWithHighRisk: 0,
			mostRecentDateWithLowRisk: Date(),
			mostRecentDateWithHighRisk: Date(),
			numberOfDaysWithLowRisk: 3,
			numberOfDaysWithHighRisk: 0,
			calculationDate: Date(),
			riskLevelPerDate: [:],
			minimumDistinctEncountersWithHighRiskPerDate: [:]
		)
	}
}
