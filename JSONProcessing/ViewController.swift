//
//  ViewController.swift
//  JSONProcessing
//
//  Created by Alpha on 23/10/18.
//  Copyright © 2018 SAG. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        makePostCall(strURL: "https://alfabet.agileappscloud.eu/networking/rest/login", strContent: "<platform><login><userName>userNikarin</userName><password>Theriyin18</password></login></platform>")
        print("Going to call second time")
        makePostCall(strURL: "https://alfabet.agileappscloud.eu/networking/rest/record/cases", strContent: "<platform><record><subject>PeriodicMaintenance</subject><description>Maintenance for the device is created.</description><type>1</type><priority>4</priority><account>1753289431</account><status>1</status><from_address>bath@softwareag.com</from_address></record></platform>")
        return
        
        let sZemantisURL : String = "http://10.60.5.238:9083/adapars/apply/drill_pmml?record={\"RPM\": 2350,\"Temperature\": 52,\"Sound\": 3.2}"
        let strZemantisResDict = GetDeviceMetricsFromServer(anAccessURL: sZemantisURL, anUserName: "Administrator", anPassword: "manage", bSync: true)
        print("Response received \(strZemantisResDict)")
        //let sUIVal = ReadValueFromDictionaryWithKey(dtInput: strZemantisResDict, stKey: "predicted_Maintenance")
        let sUIVal = ReadValueFromDictionaryRecursively(dtInput: strZemantisResDict, stKey: "predicted_Maintenance")
        print(sUIVal)
    }
    
    func makePostCall(strURL: String, strContent: String) {
        let anSem = DispatchSemaphore.init(value: 0)
        //let todosEndpoint: String = "https://alfabet.agileappscloud.eu/networking/rest/login"
        //let todosEndpoint: String = "https://alfabet.agileappscloud.eu/networking/rest/record/cases"
        let todosEndpoint: String  = strURL
        guard let todosURL = URL(string: todosEndpoint) else {
            print("Error: cannot create URL")
            return
        }
        var todosUrlRequest = URLRequest(url: todosURL)
        todosUrlRequest.httpMethod = "POST"
        //let newTodo: String = "<platform><login><userName>userNikarin</userName><password>Theriyin18</password></login></platform>"
        //let newTodo: String = "<platform><record><subject>PeriodicMaintenance</subject><description>Maintenance for the device is created.</description><type>1</type><priority>4</priority><account> </account><status>1</status><from_address>bath@softwareag.com</from_address></record></platform>"
        let newTodo: String = strContent
        let jsonTodo: Data
        do {
            /*jsonTodo = try JSONSerialization.data(withJSONObject: newTodo, options: [])
            todosUrlRequest.httpBody = jsonTodo*/
            
            todosUrlRequest.addValue("application/xml", forHTTPHeaderField: "Content-Type")
            todosUrlRequest.httpBody = newTodo.data(using: String.Encoding.utf8)
        } catch {
            print("Error: cannot create JSON from todo")
            return
        }
        
        let session = URLSession.shared
        
        let task = session.dataTask(with: todosUrlRequest) {
            (data, response, error) in
            guard error == nil else {
                print("error calling POST on /todos/1")
                print(error!)
                return
            }
            guard let responseData = data else {
                print("Error: did not receive data")
                return
            }
            print("Anj test response \(responseData)")
            // parse the result as JSON, since that's what the API provides
            do {
                guard let receivedTodo = try JSONSerialization.jsonObject(with: responseData,
                                                                          options: []) as? [String: Any] else {
                                                                            print("Could not get JSON from responseData as dictionary")
                                                                            return
                }
                print("The todo is: " + receivedTodo.description)
                
                /*guard let todoID = receivedTodo["description"] as? Int else {
                    print("Could not get todoID as int from JSON")
                    return
                }
                print("The sessionId is: \(todoID)")*/
            } catch  {
                print("error parsing response from POST on /todos")
                return
            }
            anSem.signal()
        }
        task.resume()
        anSem.wait(timeout: .distantFuture)
    }
    
    
    //Read device metrics from Server URL
    func GetDeviceMetricsFromServer(anAccessURL : String, anUserName: String, anPassword: String, bSync: Bool) -> String {
        let config = URLSessionConfiguration.default
        
        var strResponse : String = ""
        let anSem = DispatchSemaphore.init(value: 0)
        
        if (anAccessURL == nil || anAccessURL.isEmpty) {
            return strResponse
        }
        
        if (!anUserName.isEmpty && !anPassword.isEmpty) {
            let userPasswordData = "\(anUserName):\(anPassword)".data(using: .utf8)
            let base64EncodedCredential = userPasswordData!.base64EncodedString(options: Data.Base64EncodingOptions.init(rawValue: 0))
            let authString = "Basic \(base64EncodedCredential)"
            config.httpAdditionalHeaders = ["Authorization" : authString]
        }
        
        //print("URL : " + anAccessURL)
        let session = URLSession(configuration: config)
        
        let anUrl = URL(string: anAccessURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!)!
        let anUrlRequest : URLRequest = URLRequest(url: anUrl)
        var anResponse : String = ""
        let anDataTsk = session.dataTask(with: anUrlRequest as URLRequest, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                print(error?.localizedDescription ?? "")
                return
            }
            anResponse = String(data: data!, encoding: .utf8)!
            strResponse = anResponse
            if bSync == true {
                anSem.signal()
            }
            //self._DeviceMetrics = anResponse
        })
        anDataTsk.resume()
        if bSync == true {
            anSem.wait(timeout: .distantFuture)
        }
        //print("And I got this reponse : \(strResponse))")
        return strResponse
    }
    
    func ReadValueFromDictionaryRecursively(dtInput : String, stKey : String) -> String {
        var stOutput : String = ""
        if dtInput.isEmpty {
            return stOutput
        }
        var dictionary:NSDictionary?
        if let data = dtInput.data(using: String.Encoding.utf8) {
            do {
                do {
                dictionary = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject] as NSDictionary?
                }
                catch {
                    return ""
                }
                if let myDictionary = dictionary
                {
                    //let jsonMedium = dictionary?["outputs"] as! [AnyObject]
                    //print (jsonMedium["outputs"]["predicted_Maintenance"] as! String)
                    for (anKey, anValue) in myDictionary {
                        if anValue is NSArray {
                            let temp = anValue as AnyObject! as! NSArray
                            if temp != nil {
                                print ("am with array now !")
                                temp.forEach { anitem in
                                    let anDict:NSDictionary = (anitem as! [String:AnyObject] as NSDictionary?)!
                                    if anDict != nil {
                                        for(an2Key, an2Value) in anDict {
                                            print("Key is \(an2Key) Value is \(an2Value)")
                                        }
                                    }
                                    //var anDictionary = anitem as! [Any] as NSDictionary?
                                    print (anitem)
                                }
                            }
                        }
                        else
                        {
                            print("Root Key is\(anKey) with root value of \(anValue)")
                        }
                        
                        //anValue["outputs"]["predicted_Maintenance"] as! String
                        //ReadValueFromDictionaryRecursively(dtInput: anValue as! String, stKey: "Test")
                        /*var dictionary2:NSDictionary?
                         let data2 = anValue.data(using: String.Encoding.utf8)
                         dictionary2 = try JSONSerialization.jsonObject(with: data2, options: []) as? [String:AnyObject] as NSDictionary?
                         if let myDictionary2 = dictionary2
                         {
                         for (anKey2, anValue2) in myDictionary2 {
                         print("ankey2 \(anKey2)")
                         print("anValue2 \(anValue2)")
                         }
                         }*/
                    }
                    /*let anOutput = myDictionary.value(forKey: stKey) as? String
                     if (anOutput != nil) {
                     stOutput = anOutput!
                     }*/
                }
            } catch let error as NSError {
                print(error)
            }
        }
        return stOutput
    }


}

