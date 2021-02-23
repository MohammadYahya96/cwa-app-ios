////
// 🦠 Corona-Warn-App
//

import Foundation
import UIKit

final class DiaryOverviewDayCellModel {

	// MARK: - Init

	init(
		_ diaryDay: DiaryDay,
		historyExposure: HistoryExposure,
		minimumDistinctEncountersWithHighRisk: Int
	) {
		self.diaryDay = diaryDay
		self.historyExposure = historyExposure
		self.minimumDistinctEncountersWithHighRisk = minimumDistinctEncountersWithHighRisk
	}

	// MARK: - Public

	// MARK: - Internal

	let historyExposure: HistoryExposure

	var hideExposureHistory: Bool {
		switch historyExposure {
		case .none:
			return true
		case .encounter:
			return false
		}
	}

	var exposureHistoryAccessibilityIdentifier: String? {
		switch historyExposure {
		case let .encounter(risk):
			switch risk {
			case .low:
				return AccessibilityIdentifiers.ContactDiaryInformation.Overview.riskLevelLow
			case .high:
				return AccessibilityIdentifiers.ContactDiaryInformation.Overview.riskLevelHigh
			}
		case .none:
			return nil
		}
	}

	var exposureHistoryImage: UIImage? {
		switch historyExposure {
		case let .encounter(risk):
			switch risk {
			case .low:
				return UIImage(imageLiteralResourceName: "Icons_Attention_low")
			case .high:
				return UIImage(imageLiteralResourceName: "Icons_Attention_high")
			}
		case .none:
			return nil
		}
	}

	var exposureHistoryTitle: String? {
		switch historyExposure {
		case let .encounter(risk):
			switch risk {
			case .low:
				return AppStrings.ContactDiary.Overview.lowRiskTitle
			case .high:
				return AppStrings.ContactDiary.Overview.increasedRiskTitle
			}

		case .none:
			return nil
		}
	}

	var exposureHistoryDetail: String? {
		switch historyExposure {
		case let .encounter(risk):
			switch risk {
			case .low:
				return selectedEntries.isEmpty ? AppStrings.ContactDiary.Overview.riskTextStandardCause : [AppStrings.ContactDiary.Overview.riskTextStandardCause, AppStrings.ContactDiary.Overview.riskTextDisclaimer].joined(separator: "\n")
			case .high:
				return computeExposureHistoryDetail()
			}

		case .none:
			return nil
		}
	}

	var selectedEntries: [DiaryEntry] {
		diaryDay.selectedEntries
	}

	var formattedDate: String {
		diaryDay.formattedDate
	}
	
	func computeExposureHistoryDetail() -> String {
		if minimumDistinctEncountersWithHighRisk > 0 {
			return diaryDay.selectedEntries.isEmpty ? AppStrings.ContactDiary.Overview.riskTextStandardCause : [AppStrings.ContactDiary.Overview.riskTextStandardCause, AppStrings.ContactDiary.Overview.riskTextDisclaimer].joined(separator: "\n")
		} else {
			return diaryDay.selectedEntries.isEmpty ? AppStrings.ContactDiary.Overview.riskTextLowRiskEncountersCause : [AppStrings.ContactDiary.Overview.riskTextLowRiskEncountersCause, AppStrings.ContactDiary.Overview.riskTextDisclaimer].joined(separator: "\n")
		}
	}

	// MARK: - Private

	private let diaryDay: DiaryDay
	private let minimumDistinctEncountersWithHighRisk: Int
}
