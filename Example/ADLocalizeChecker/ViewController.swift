//
//  ViewController.swift
//  ADLocalizeChecker
//
//  Created by Claire Peyron on 06/01/2021.
//

import UIKit
import ADUtils

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        let label = UILabel()
        label.textAlignment = .center
        view.addSubview(label)
        label.ad_pinToSuperview()
        label.validKeys()
        label.keyFormatIssues()
        label.keyUsageIssues()
    }
}

private extension UILabel {

    // MARK: - UILabel

    func validKeys() {
        let arg1 = "argument1".localized()
        let arg2 = "argument2".localized()
        let arg3 = "argument3".localized()
        text = "regular_key".localized()
        let parameter = "argument1"
        text = String(format: "regular_key_2".localized(), parameter)
        text = String(
            format: "regular_key_3".localized(),
            arg1,
            arg2,
            arg3
        )
        text = String(format: "regular_key_4".localized(), 2, 3)
        text = String(format: "formatted_key_redundant_call".localized(), parameter)
        text = String(format: "formatted_key_redundant_call".localized(), parameter)
        text = localisationCustomPattern("custom_pattern_key")
        text = localisationCustomPattern2("custom_pattern_key")
        _ = "ad_utils_attributed_string_two_args_format".localized().attributedString(
            arguments: [arg1, arg2],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
        _ = "ad_utils_attributed_string_three_args_format".localized().attributedString(
            arguments: [
                arg1,
                arg2,
                arg3
            ],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
        _ = "ad_utils_attributed_string_four_args_format".localized().attributedString(
            arguments: [
                arg1,
                arg2,
                arg3,
                arg2
            ],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
        _ = "ad_utils_attributed_string_single_arg_format".localized().attributedString(
            arguments: [arg1],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
        _ = "key_to_bypass_2".localized().attributedString(
            arguments: ["argument1", "argument2", "argument3"],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
    }

    func keyFormatIssues() {
        text = "bad_format_key".localized()
        text = "bad_format_key_2".localized()
        text = String(format: "bad_format_key_3".localized(), "argument1", "argument2")
        text = "missing_key".localized()
        text = "unstranlated_key".localized()
        text = "redundant_key".localized()
        let arg1 = "argument1".localized()
        let arg2 = "argument2".localized()
        text = String(format: "bad_arguments_format".localized(), arg1, arg2)
        text = String(format: "bad_arguments_format_2".localized(), arg1, arg2)
    }

    func keyUsageIssues() {
        text = NSLocalizedString("forbidden_pattern", comment: "")
        text = (isEnabled ? "bad_pattern_key" : "bad_pattern_key_2").localized()
        text = String(format: "bad_arguments_count_key".localized(), "argument1")
        text = String(
            format: "bad_arguments_count_key_2".localized(),
            "argument1",
            "argument2"
        )
        _ = "bad_formatted_key_usage".localized()
        text = String(
            format: "bad_formatted_key_usage".localized(),
            "argument1",
            "argument2"
        )
        text = String(
            format: "bad_formatted_key_usage".localized(),
            "argument3",
            "argument4"
        )
        text = "bad_formatted_key_usage".localized()
        _ = "ad_utils_attributed_string_format_bad_arguments_count".localized().attributedString(
            arguments: ["argument1", "argument2", "argument3"],
            defaultAttributes: [:],
            formatAttributes: [:]
        )
    }

    // MARK: - Private

    private func localisationCustomPattern(_ key: String) -> String {
        return "\(key)".localized() // bypass-generic-error
    }

    private func localisationCustomPattern2(_ key_generic_error: String) -> String {
        return "\(key_generic_error)".localized()
    }
}
