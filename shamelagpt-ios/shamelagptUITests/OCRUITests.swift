//
//  OCRUITests.swift
//  shamelagptUITests
//
//  UI tests for OCR and camera functionality
//

import XCTest

final class OCRUITests: LocalizedUITestCase {
    override class var supportedLanguages: [String] { ["en"] }

    // MARK: - Localized Labels

    private var addImageLabel: String { localized("imagePicker.addImage") }
    private var takePhotoLabel: String { localized("imagePicker.takePhoto") }
    private var chooseFromLibraryLabel: String { localized("imagePicker.chooseFromLibrary") }
    private var cancelLabel: String { localized("common.cancel") }
    private var permissionRequiredLabel: String { localized("error.permissionRequired") }
    private var openSettingsLabel: String { localized("error.openSettings") }
    private var sendForFactCheckLabel: String { localized("ocr.sendForFactCheck") }
    private var doneLabel: String { localized("done") }
    private var okLabel: String { localized("common.ok") }

    // MARK: - Camera Button Tests

    private func launchToChat(overrides: [String: String] = [:], includeReset: Bool = true) {
        UITestLauncher.launch(app: app, includeReset: includeReset, overrides: overrides)
        skipWelcomeIfNeeded(navigateToChat: true)
        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 6),
            "Chat input should be visible before running OCR flow"
        )
    }

    func testCameraButtonVisible() throws {
        launchToChat()
        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5), "Camera button should be visible")
        XCTAssertTrue(cameraButton.isHittable, "Camera button should be tappable")
    }

    func testImageSourceSheetShowsOptions() throws {
        launchToChat()

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)

        XCTAssertTrue(
            waitForImageSourceSheet(timeout: 5),
            "Image source sheet should appear after tapping camera button"
        )

        XCTAssertTrue(app.buttons[takePhotoLabel].waitForExistence(timeout: 3), "Camera option should be available")
        XCTAssertTrue(
            app.buttons[chooseFromLibraryLabel].waitForExistence(timeout: 3),
            "Photo library option should be available"
        )
    }

    func testCameraPermissionDeniedShowsGuidance() throws {
        launchToChat(overrides: ["SIMULATE_CAMERA_PERMISSION_DENIED": "true"])

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)

        let permissionTitle = app.staticTexts[permissionRequiredLabel]
        let settingsButton = app.buttons[openSettingsLabel]

        XCTAssertTrue(permissionTitle.waitForExistence(timeout: 6), "Permission guidance should be displayed")
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 6), "Permission guidance should include Settings action")
    }

    // MARK: - Camera Flow Tests

    func testImageSourceOptionsProgressToOCRConfirmation() throws {
        launchToChat(overrides: ["SIMULATE_OCR_SUCCESS": "true"])

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)

        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")
        let cameraOption = app.buttons[takePhotoLabel]
        XCTAssertTrue(cameraOption.waitForExistence(timeout: 3), "Take photo option should be available")
        cameraOption.tap()
        XCTAssertTrue(
            waitForOCRConfirmation(timeout: 6),
            "Selecting camera should progress to OCR confirmation in UI tests"
        )
        let confirmationCancelButton = app.buttons[cancelLabel].firstMatch
        XCTAssertTrue(confirmationCancelButton.waitForExistence(timeout: 3))
        confirmationCancelButton.tap()

        XCTAssertTrue(app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 4))
        tapCameraButton(cameraButton)
        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")
        let photoLibraryOption = app.buttons[chooseFromLibraryLabel]
        XCTAssertTrue(photoLibraryOption.waitForExistence(timeout: 3), "Choose from library option should be available")
        photoLibraryOption.tap()
        XCTAssertTrue(
            waitForOCRConfirmation(timeout: 6),
            "Selecting photo library should progress to OCR confirmation in UI tests"
        )
    }

    func testCancelImageSelectionWorks() throws {
        launchToChat()

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)
        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")

        let cancelButton = app.buttons[cancelLabel]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel button should exist on image source sheet")
        cancelButton.tap()

        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 4),
            "Should return to chat screen after canceling image source selection"
        )
    }

    // MARK: - OCR Confirmation Tests

    func testOCRConfirmationDisplaysContentAndIsEditable() throws {
        let extracted = "Sample extracted text"
        XCTAssertTrue(
            openOCRConfirmation(
                overrides: [
                    "SIMULATE_OCR_SUCCESS": "true",
                    "OCR_EXTRACTED_TEXT": extracted,
                    "OCR_DETECTED_LANGUAGE": "Arabic"
                ],
                expectedText: extracted
            ),
            "OCR confirmation should appear with extracted text"
        )

        let textView = ocrTextEditor(expectedText: extracted)
        XCTAssertTrue(textView.waitForExistence(timeout: 3), "Extracted text should be displayed in confirmation dialog")

        let languageLabel = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Arabic")).firstMatch
        XCTAssertTrue(languageLabel.waitForExistence(timeout: 3), "Detected language should be displayed in confirmation")

        XCTAssertTrue(UITestLauncher.safeTypeText(in: textView, text: " edited"), "OCR text editor should accept typing")

        let value = textView.value as? String ?? ""
        XCTAssertTrue(value.contains("edited"), "OCR text should be editable and accept user input")
    }

    func testOCRConfirmationSendsMessage() throws {
        let message = "Text to send as fact-check"
        XCTAssertTrue(
            openOCRConfirmation(
                overrides: [
                    "SIMULATE_OCR_SUCCESS": "true",
                    "OCR_EXTRACTED_TEXT": message
                ],
                expectedText: message
            ),
            "OCR confirmation should appear before sending"
        )

        let sendButton = app.buttons[sendForFactCheckLabel]
        let doneButton = app.buttons[doneLabel]
        if sendButton.waitForExistence(timeout: 3) {
            sendButton.tap()
        } else {
            XCTAssertTrue(doneButton.waitForExistence(timeout: 3), "Either Send for Fact Check or Done should exist")
            doneButton.tap()
        }

        let sentMessage = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", message)).firstMatch
        XCTAssertTrue(sentMessage.waitForExistence(timeout: 8), "OCR text should be sent as message after confirmation")
    }

    func testOCRConfirmationCancelWorks() throws {
        let cancelledText = "Text to cancel"
        XCTAssertTrue(
            openOCRConfirmation(
                overrides: [
                    "SIMULATE_OCR_SUCCESS": "true",
                    "OCR_EXTRACTED_TEXT": cancelledText
                ],
                expectedText: cancelledText
            ),
            "OCR confirmation should appear before cancel"
        )

        let cancelButton = app.buttons[cancelLabel].firstMatch
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 3), "Cancel action should be visible in OCR confirmation")
        cancelButton.tap()

        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 4),
            "Should return to chat screen after cancelling OCR confirmation"
        )
        XCTAssertFalse(app.staticTexts[cancelledText].exists, "Cancelled OCR text should not appear as a message")
    }

    // MARK: - Error Tests

    func testOCRNoTextFoundShowsError() throws {
        launchToChat(overrides: ["SIMULATE_OCR_NO_TEXT": "true"])

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)
        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")
        XCTAssertTrue(selectAnyImageSource(), "An image source option should be selectable")

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6), "OCR no-text scenario should present an error alert")
    }

    func testOCRInvalidImageShowsError() throws {
        launchToChat(overrides: ["SIMULATE_OCR_INVALID_IMAGE": "true"])

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)
        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")
        XCTAssertTrue(selectAnyImageSource(), "An image source option should be selectable")

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6), "OCR invalid-image scenario should present an error alert")
    }

    func testOCRErrorDismissible() throws {
        launchToChat(overrides: ["SIMULATE_OCR_ERROR": "true"])

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        XCTAssertTrue(cameraButton.waitForExistence(timeout: 5))
        tapCameraButton(cameraButton)
        XCTAssertTrue(waitForImageSourceSheet(timeout: 5), "Image source sheet should appear")
        XCTAssertTrue(selectAnyImageSource(), "An image source option should be selectable")

        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 6), "OCR error scenario should present an alert")

        let okButton = app.buttons[okLabel]
        XCTAssertTrue(okButton.waitForExistence(timeout: 3), "Alert should provide OK action")
        okButton.tap()

        XCTAssertFalse(alert.exists, "Error alert should be dismissible")
        XCTAssertTrue(
            app.textViews[UITestID.Chat.messageInputField].waitForExistence(timeout: 4),
            "Should return to chat screen after dismissing OCR error"
        )
    }

    // MARK: - Helpers

    @discardableResult
    private func openOCRConfirmation(overrides: [String: String], expectedText: String? = nil) -> Bool {
        launchToChat(overrides: overrides)

        let cameraButton = app.buttons[UITestID.Chat.cameraButton]
        guard cameraButton.waitForExistence(timeout: 5) else { return false }
        tapCameraButton(cameraButton)

        guard waitForImageSourceSheet(timeout: 5) else { return false }
        guard selectAnyImageSource() else { return false }

        return waitForOCRConfirmation(timeout: 6, expectedText: expectedText)
    }

    /// Waits for the image source picker sheet to appear.
    @discardableResult
    private func waitForImageSourceSheet(timeout: TimeInterval = 3) -> Bool {
        if app.sheets.firstMatch.waitForExistence(timeout: timeout) {
            return true
        }
        if app.navigationBars[addImageLabel].waitForExistence(timeout: timeout) {
            return true
        }
        if app.buttons[takePhotoLabel].waitForExistence(timeout: timeout) {
            return true
        }
        if app.buttons[chooseFromLibraryLabel].waitForExistence(timeout: timeout) {
            return true
        }
        return false
    }

    @discardableResult
    private func selectAnyImageSource() -> Bool {
        let cameraOption = app.buttons[takePhotoLabel]
        if cameraOption.waitForExistence(timeout: 2) {
            cameraOption.tap()
            return true
        }

        let libraryOption = app.buttons[chooseFromLibraryLabel]
        if libraryOption.waitForExistence(timeout: 2) {
            libraryOption.tap()
            return true
        }

        return false
    }

    @discardableResult
    private func waitForOCRConfirmation(timeout: TimeInterval, expectedText: String? = nil) -> Bool {
        let sendButton = app.buttons[sendForFactCheckLabel]
        if sendButton.waitForExistence(timeout: timeout) {
            if let expectedText {
                return ocrTextEditor(expectedText: expectedText).waitForExistence(timeout: 2)
            }
            return true
        }

        let doneButton = app.buttons[doneLabel]
        if doneButton.waitForExistence(timeout: timeout) {
            if let expectedText {
                return ocrTextEditor(expectedText: expectedText).waitForExistence(timeout: 2)
            }
            return true
        }

        return false
    }

    private func ocrTextEditor(expectedText: String? = nil) -> XCUIElement {
        if let expectedText {
            let predicate = NSPredicate(
                format: "identifier != %@ AND value CONTAINS[c] %@",
                UITestID.Chat.messageInputField,
                expectedText
            )
            return app.textViews.matching(predicate).firstMatch
        }

        let predicate = NSPredicate(format: "identifier != %@", UITestID.Chat.messageInputField)
        return app.textViews.matching(predicate).firstMatch
    }

    /// Reliably taps the camera button, retrying with a coordinate tap if needed.
    private func tapCameraButton(_ button: XCUIElement) {
        if button.isHittable {
            button.tap()
        } else {
            button.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }
}
