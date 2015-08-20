//
//  ViewController.swift
//  Y Time
//
//  Created by Micah Wilson on 6/24/15.
//  Copyright (c) 2015 Micah Wilson. All rights reserved.
//

import UIKit
import CoreData
class ViewController: UIViewController, UIWebViewDelegate, MWTimeTravelDelegate, UITextFieldDelegate {
    @IBOutlet weak var navBar: UINavigationBar!
    @IBOutlet weak var weeklyTimeLabel: UILabel!
    @IBOutlet weak var periodTimeLabel: UILabel!
    @IBOutlet weak var clockedInLabel: UILabel!
    @IBOutlet weak var timeTravelSlider: MWTimeTravel!
    @IBOutlet weak var clockInButton: UIButton!
    @IBOutlet weak var clockOutButton: UIButton!
    let context = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext!
    let appDel = UIApplication.sharedApplication().delegate as! AppDelegate
    let settingsView = SettingsView()
    var clockedIn = false
    var loginScreen: LoginView?
    var webView: UIWebView?
    var previousURL: String?
    var currentUser: NSManagedObject?
    var weeklyTime: Float = 0.0
    var periodTime: Float = 0.0
    var username = ""
    var password = ""
    var weeklyTimeLoaded: Float = 0.0
    var periodTimeLoaded: Float = 0.0
    var weeklyTimeString: String?
    var periodTimeString: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Set Up
        self.timeTravelSlider.delegate = self
        self.clockInButton.layer.cornerRadius = 8.0
        self.clockOutButton.layer.cornerRadius = 8.0
 
        //Get user if exists
        let request = NSFetchRequest(entityName: "User")

        self.currentUser = (self.context.executeFetchRequest(request, error: nil) as! [NSManagedObject]).first
        
        
        if let user = self.currentUser {
            self.username = user.valueForKey("username")! as! String
            self.password = user.valueForKey("password")! as! String
            self.loadLoginBYU()
            return
        } else {
            self.loginScreen = LoginView(frame: self.view.frame)
            self.loginScreen?.loginButton.addTarget(self, action: "submitLoginForm:", forControlEvents: .TouchUpInside)
            self.view.addSubview(self.loginScreen!)
            self.loginScreen?.usernameField.becomeFirstResponder()
            self.loginScreen?.passwordField.delegate = self
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        //Set Up Settings view and folder action
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "closeFolder:"))
        self.settingsView.frame = CGRectMake(0, self.view.frame.height, self.view.frame.width, self.view.frame.height/2.2)
        self.appDel.window?.addSubview(settingsView)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        submitLoginForm(UIButton())
        return true
    }
    
    func submitLoginForm(sender: UIButton) {
        print("Log in pressed", appendNewline: false)
        self.loginPressed(sender)
    }
    
    func loginPressed(sender: UIButton) {
        self.spinYLogo()
        self.loginScreen?.loginButton.enabled = false
        self.loginScreen?.loginButton.alpha = 0.0
        self.username = self.loginScreen!.usernameField.text!
        self.password = self.loginScreen!.passwordField.text!
        self.loadLoginBYU()
    }
    
    func loadLoginBYU() {
        self.previousURL = nil
        self.webView = UIWebView(frame: CGRectZero)
        self.webView!.delegate = self
        self.webView!.loadRequest(NSURLRequest(URL: NSURL(string: "https://hrms.byu.edu/psc/ps/EMPLOYEE/HRMS/c/Y_EMPLOYEE_SELF_SERVICE.Y_TL_TIME_ENTRY.GBL")!))
    }
    
    func spinYLogo() {
        let rotationAnimation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotationAnimation.toValue = NSNumber(float: Float(M_2_PI * 10 * 5))
        rotationAnimation.duration = 5.0
        rotationAnimation.cumulative = true
        rotationAnimation.repeatCount = 5
        self.loginScreen?.logoImageView.layer.addAnimation(rotationAnimation, forKey: "spinner")
    }
    
    func giveErrorMessageForLogin() {
        self.loginScreen?.logoImageView.layer.removeAllAnimations()
        self.loginScreen?.usernameField.textColor = .redColor()
        self.loginScreen?.passwordField.textColor = .redColor()
        self.loginScreen?.loginButton.enabled = true
        self.loginScreen?.loginButton.alpha = 1.0
    }
    
    func loginSuccessful() {
        if currentUser == nil {
            let user: AnyObject = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.context)
            user.setValue(loginScreen!.usernameField.text!, forKey: "username")
            user.setValue(loginScreen!.passwordField.text!, forKey: "password")

            self.context.save(nil)

        }
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.loginScreen?.transform = CGAffineTransformMakeTranslation(0, self.view.frame.height)
        }) { (finished) -> Void in
            self.loginScreen?.removeFromSuperview()
        }
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func webViewDidStartLoad(webView: UIWebView) {
        //Show some sort of spinner.
        
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        
       // print(webView.request?.URL?.path, appendNewline: false)
        if let wrongURL = self.previousURL {
            if wrongURL == webView.request?.URL?.path {
                print("information incorrect", appendNewline: false)
                webView.stopLoading()
                self.giveErrorMessageForLogin()
                return
            }
        }
    
        if webView.request?.URL?.path == "/psc/ps/EMPLOYEE/HRMS/c/Y_EMPLOYEE_SELF_SERVICE.Y_TL_TIME_ENTRY.GBL" {
            //Login was successful
            let weeklyJS = "document.getElementById('Y_TL_WRK_Y_TL_W_TOTAL_M').value"
            let periodJS = "document.getElementById('Y_TL_WRK_Y_TL_P_TOTAL_M').value"
            let jobTitleJS = "document.getElementsByClassName('PSHYPERLINK')[3].innerHTML"
            let clockedInJS = "document.getElementById('Y_TL_WRK_STATUS$0').innerHTML"
            let weeklyHoursValue = webView.stringByEvaluatingJavaScriptFromString(weeklyJS)
            let periodHoursValue = webView.stringByEvaluatingJavaScriptFromString(periodJS)
            self.weeklyTimeLabel.text = weeklyHoursValue
            self.weeklyTime = weeklyHoursValue!.convertToFloat()
            self.weeklyTimeLoaded = weeklyHoursValue!.convertToFloat()
            self.weeklyTimeString = weeklyHoursValue
            self.periodTimeLabel.text = periodHoursValue
            self.periodTime = periodHoursValue!.convertToFloat()
            self.periodTimeLoaded = periodHoursValue!.convertToFloat()
            self.periodTimeString = periodHoursValue
            self.navBar.topItem?.title = webView.stringByEvaluatingJavaScriptFromString(jobTitleJS)!
            
            if webView.stringByEvaluatingJavaScriptFromString(clockedInJS)!.lowercaseString.rangeOfString("in") == nil {
                self.clockedIn = false
                (self.view as! YTimeView).clockedIn = self.clockedIn
                self.view.setNeedsDisplay()
            } else {
                self.clockedIn = true
                (self.view as! YTimeView).clockedIn = self.clockedIn
                self.view.setNeedsDisplay()
            }
            
            if webView.stringByEvaluatingJavaScriptFromString(jobTitleJS)!.lowercaseString.rangeOfString("mtc") != nil {
                self.clockInButton.enabled = false
                self.clockOutButton.enabled = false
            }
            
            self.loginSuccessful()
            return
        }
        
        if (count(username) != 0 && count(password) != 0) {
            let usernameJS = "document.getElementById('netid').value = '\(username)'"
            let passwordJS = "document.getElementById('password').value = '\(password)'"
            let submitJS = "document.getElementsByClassName('submit')[0].click()"
            webView.stringByEvaluatingJavaScriptFromString(usernameJS)
            webView.stringByEvaluatingJavaScriptFromString(passwordJS)
            webView.stringByEvaluatingJavaScriptFromString(submitJS)
            
        }
        self.previousURL = webView.request?.URL?.path
    }
    
    @IBAction func clockInPressed(sender: AnyObject) {
        let clockInJS = "document.getElementById('win0divY_TL_WRK_Y_TL_CLOCK_IN$0').click()"
        self.webView?.stringByEvaluatingJavaScriptFromString(clockInJS)
    }
    
    @IBAction func clockOutPressed(sender: AnyObject) {
        let clockOutJS = "document.getElementById('win0divY_TL_WRK_Y_TL_CLOCK_OUT$0').click()"
        self.webView?.stringByEvaluatingJavaScriptFromString(clockOutJS)
    }
    
    @IBAction func reloadData(sender: AnyObject) {
        self.webView!.loadRequest(NSURLRequest(URL: NSURL(string: "https://hrms.byu.edu/psc/ps/EMPLOYEE/HRMS/c/Y_EMPLOYEE_SELF_SERVICE.Y_TL_TIME_ENTRY.GBL")!))
        self.timeTravelSlider.resetSlider()
    }
    
    func timeDidTravel(timeChange: Float) {
        self.weeklyTime += timeChange
        self.periodTime += timeChange
        
        self.weeklyTimeLabel.text = String().convertToString(self.weeklyTime)
        self.periodTimeLabel.text = String().convertToString(self.periodTime)
    }

    func timeDidFinishTraveling() {
        self.weeklyTimeLabel.text = self.weeklyTimeString
        self.periodTimeLabel.text = self.periodTimeString
        self.weeklyTime = self.weeklyTimeLoaded
        self.periodTime = self.periodTimeLoaded
    }
    
    @IBAction func openFolder(sender: UITabBarItem) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.view.transform = CGAffineTransformMakeScale(0.8, 0.8)
            self.settingsView.transform = CGAffineTransformMakeTranslation(0, -self.view.frame.height/2.2)
            }, completion: nil)
    }
    
    func closeFolder(sender: UITapGestureRecognizer) {
        UIView.animateWithDuration(0.5, delay: 0.0, usingSpringWithDamping: 0.5, initialSpringVelocity: 3, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.view.transform = CGAffineTransformMakeScale(1.0, 1.0)
            self.settingsView.transform = CGAffineTransformMakeTranslation(0, 0)
            }, completion: nil)
    }
    
}

