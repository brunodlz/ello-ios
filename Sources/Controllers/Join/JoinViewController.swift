//
//  JoinViewController.swift
//  Ello
//
//  Created by Sean Dougherty on 11/24/14.
//  Copyright (c) 2014 Ello. All rights reserved.
//

import UIKit

public class JoinViewController: BaseElloViewController {

    @IBOutlet weak public var scrollView: UIScrollView!
    @IBOutlet weak public var elloLogo: ElloLogoView!
    @IBOutlet weak public var emailView: ElloTextFieldView!
    @IBOutlet weak public var usernameView: ElloTextFieldView!
    @IBOutlet weak public var passwordView: ElloTextFieldView!
    @IBOutlet weak public var aboutButton: ElloTextButton!
    @IBOutlet weak public var loginButton: ElloTextButton!
    @IBOutlet weak public var joinButton: ElloButton!

    // error checking
    var queueEmailValidation: Functional.BasicBlock!
    var queueUsernameValidation: Functional.BasicBlock!
    var queuePasswordValidation: Functional.BasicBlock!

    required public init() {
        super.init(nibName: "JoinViewController", bundle: nil)
        queueEmailValidation = Functional.debounce(0.5) { self.validateEmail(self.emailView.textField.text) }
        queueUsernameValidation = Functional.debounce(0.5) { self.validateUsername(self.usernameView.textField.text) }
        queuePasswordValidation = Functional.debounce(0.5) { self.validatePassword(self.passwordView.textField.text) }
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupStyles()
        setupViews()
        setupNotificationObservers()
    }

    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        Tracker.sharedTracker.screenAppeared("Join")
    }

    override public func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        removeNotificationObservers()
    }

    // MARK: Private

    private func setupStyles() {
        UIApplication.sharedApplication().setStatusBarHidden(true, withAnimation: .Slide)
        scrollView.contentSize = view.bounds.size
        modalTransitionStyle = .CrossDissolve
        scrollView.backgroundColor = UIColor.grey3()
        view.backgroundColor = UIColor.grey3()
        view.setNeedsDisplay()
    }

    private func setupViews() {
        joinButton.enabled = false

        ElloTextFieldView.styleAsUsername(usernameView)
        usernameView.textField.delegate = self
        usernameView.textFieldDidChange = self.usernameChanged

        ElloTextFieldView.styleAsEmail(emailView)
        emailView.textField.delegate = self
        emailView.textFieldDidChange = self.emailChanged

        ElloTextFieldView.styleAsPassword(passwordView)
        passwordView.textField.delegate = self
        passwordView.textFieldDidChange = self.passwordChanged
    }

    private func setupNotificationObservers() {
        let center = NSNotificationCenter.defaultCenter()
        center.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        center.addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }

    private func removeNotificationObservers() {
        let center = NSNotificationCenter.defaultCenter()
        center.removeObserver(self)
    }

    private func join() {
        if allFieldsValid() {
            self.elloLogo.animateLogo()

            emailView.textField.resignFirstResponder()
            usernameView.textField.resignFirstResponder()
            passwordView.textField.resignFirstResponder()

            let service = UserService()
            let email = emailView.textField.text
            let username = usernameView.textField.text
            let password = passwordView.textField.text
            service.join(email: email, username: username, password: password, success: { user, responseConfig in
                let authService = AuthService()
                authService.authenticate(email: email,
                    password: password,
                    success: {
                        self.showMainScreen(user, responseConfig: responseConfig)
                    },
                    failure: { (error, statusCode) -> () in
                        self.showSignInScreen(email, password)
                    })
            },
            failure: { error, statusCode in
                self.elloLogo.animateLogo()
            })
        }
    }

    private func showMainScreen(user: User, responseConfig: ResponseConfig) {
        let vc = ElloTabBarController.instantiateFromStoryboard()
        vc.setProfileData(user, responseConfig: responseConfig)
        self.elloLogo.stopAnimatingLogo()
        let window = self.view.window!
        self.presentViewController(vc, animated: true, completion: {
            window.rootViewController = vc
        })
    }

    private func showSignInScreen(email: String, _ password: String) {
        let signInController = SignInViewController()
        let window = self.view.window!
        let view = signInController.view
        signInController.emailTextField.text = email
        signInController.passwordTextField.text = password
        signInController.enterButton.enabled = true

        self.presentViewController(signInController, animated:true, completion: {
            window.rootViewController = signInController
        })
    }

    private func showSignInScreen() {
        let signInController = SignInViewController()
        let window = self.view.window!
        self.presentViewController(signInController, animated:true, completion: {
            window.rootViewController = signInController
        })
    }

    private func showAboutScreen() {
        //TODO: show about screen
        println("about tapped")
        // let aboutController = AboutViewController()
        // let window = self.view.window!
        // self.presentViewController(aboutController, animated:true, completion: {
        //     window.rootViewController = aboutController
        // })
    }

}


// MARK: Keyboard Events
extension JoinViewController {

    func keyboardWillShow(notification: NSNotification) {
        keyboardWillChangeFrame(notification, showsKeyboard: true)
    }

    func keyboardWillHide(notification: NSNotification) {
        keyboardWillChangeFrame(notification, showsKeyboard: false)
    }

    private func keyboardWillChangeFrame(notification: NSNotification, showsKeyboard: Bool) {
        if let userInfo = notification.userInfo {
            let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            let keyboardViewEndFrame = view.convertRect(keyboardScreenEndFrame, fromView: view.window)

            if shouldAdjustScrollViewForKeyboard(keyboardViewEndFrame) || !showsKeyboard {
                let keyboardHeight = showsKeyboard ? keyboardViewEndFrame.size.height : 0
                let adjustedInsets = UIEdgeInsetsMake(
                    scrollView.contentInset.top,
                    scrollView.contentInset.left,
                    keyboardHeight,
                    scrollView.contentInset.right
                )
                scrollView.contentInset = adjustedInsets
                scrollView.scrollIndicatorInsets = adjustedInsets
            }
        }
    }

    private func shouldAdjustScrollViewForKeyboard(rect:CGRect) -> Bool {
        return (rect.origin.y + rect.size.height) == view.bounds.size.height
    }

}


// MARK: UITextFieldDelegate
extension JoinViewController: UITextFieldDelegate {

    public func textFieldShouldReturn(textField: UITextField) -> Bool {
        switch textField {
        case emailView.textField:
            usernameView.textField.becomeFirstResponder()
        case usernameView.textField:
            passwordView.textField.becomeFirstResponder()
        case passwordView.textField:
            join()
        default:
            return false
        }
        return true
    }

}


// MARK: IBActions
extension JoinViewController {

    @IBAction func joinTapped(sender: ElloButton) {
        join()
    }

    @IBAction func loginTapped(sender: ElloTextButton) {
        showSignInScreen()
    }

    @IBAction func aboutTapped(sender: ElloTextButton) {
        showAboutScreen()
    }

}


// MARK: Text field validation
extension JoinViewController {

    private func allFieldsValid() -> Bool {
        return !emailView.hasError && !usernameView.hasError && !passwordView.hasError
    }

    public func revalidateAndResizeViews() {
        joinButton.enabled = allFieldsValid()
    }

    private func emailChanged(text: String) {
        self.emailView.setState(.Loading)
        queueEmailValidation()
    }

    private func usernameChanged(text: String) {
        self.usernameView.setState(.Loading)
        queueUsernameValidation()
    }

    private func passwordChanged(text: String) {
        self.passwordView.setState(.Loading)
        queuePasswordValidation()
    }

    private func validateEmail(text: String) {
        if text.isEmpty {
            self.emailView.setState(.Error)
            let msg = NSLocalizedString("Email is required.", comment: "email is required message")
            self.emailView.setErrorMessage(msg)
            self.revalidateAndResizeViews()
        }
        else if text.isValidEmail() {
            AvailabilityService().emailAvailability(text, success: { availability in
                if text != self.emailView.textField.text { return }

                let state: ValidationState = availability.isEmailAvailable ? .OK : .Error
                self.emailView.setState(state)

                if !availability.isEmailAvailable {
                    let msg = NSLocalizedString("That email is invalid.\nPlease try again.", comment: "invalid email message")
                    self.emailView.setErrorMessage(msg)
                }
                else {
                    self.emailView.setErrorMessage("")
                }

                self.revalidateAndResizeViews()
            }, failure: { _, _ in
                self.emailView.setState(.None)
                self.emailView.setErrorMessage("")
                self.revalidateAndResizeViews()
            })
        }
        else {
            self.emailView.setState(.Error)
            let msg = NSLocalizedString("That email is invalid.\nPlease try again.", comment: "invalid email message")
            self.emailView.setErrorMessage(msg)
            self.revalidateAndResizeViews()
        }
    }

    private func validateUsername(text: String) {
        if text.isEmpty {
            self.usernameView.setState(.Error)
            self.usernameView.setMessage("")
            let msg = NSLocalizedString("Username is required.", comment: "username is required message")
            self.usernameView.setErrorMessage(msg)
            self.revalidateAndResizeViews()
        }
        else {
            AvailabilityService().usernameAvailability(text, success: { availability in
                if text != self.usernameView.textField.text { return }

                let state: ValidationState = availability.isUsernameAvailable ? .OK : .Error
                self.usernameView.setState(state)

                if !availability.isUsernameAvailable {
                    let msg = NSLocalizedString("Username already exists.\nPlease try a new one.", comment: "username exists error message")
                    self.usernameView.setErrorMessage(msg)

                    if !availability.usernameSuggestions.isEmpty {
                        let suggestions = ", ".join(availability.usernameSuggestions)
                        let msg = String(format: NSLocalizedString("Here are some available usernames -\n%@", comment: "username suggestions message"), suggestions)
                        self.usernameView.setMessage(msg)
                    }
                    else {
                        self.usernameView.setMessage("")
                    }
                }
                else {
                    self.usernameView.setMessage("")
                    self.usernameView.setErrorMessage("")
                }

                self.revalidateAndResizeViews()
            }, failure: { _, _ in
                self.usernameView.setState(.None)
                self.usernameView.setMessage("")
                self.usernameView.setErrorMessage("")
                self.revalidateAndResizeViews()
            })
        }
    }

    private func validatePassword(text: String) {
        if text.isValidPassword() {
            self.passwordView.setState(.OK)
            self.passwordView.setErrorMessage("")
            self.revalidateAndResizeViews()
        }
        else {
            self.passwordView.setState(.Error)
            let msg = NSLocalizedString("Password must be at least 8\ncharacters long.", comment: "password length error message")
            self.passwordView.setErrorMessage(msg)
            self.revalidateAndResizeViews()
        }
    }

}

