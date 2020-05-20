//
//  ViewController.swift
//  testdemo
//
//  Created by jayce on 2020/5/19.
//  Copyright © 2020 jayce. All rights reserved.
//

import UIKit
import MobileCoreServices

class ViewController: UIViewController {

    @IBOutlet weak var progressView: UIProgressView!
    var serverUrl = URL(string: "http://127.0.0.1:9090/uploadMore")!
    let multipartFormName = "file"
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func startUpload(_ sender: Any) {

        progressView.progress = 0.0
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let parameters = [
            "file1": "1",
            "file2": "2"
        ]
        
        let bUrl = Bundle.main.url(forResource: "SwiftBook", withExtension: "bundle")!
        let bundle = Bundle(url: bUrl)!
        
        let files = [
            (
                name: multipartFormName,
                path: bundle.path(forResource: "1", ofType: "HEIC")!
            ),
            (
                name: multipartFormName,
                path: bundle.path(forResource: "2", ofType: "HEIC")!
            )
        ]

        var request = URLRequest(url: serverUrl)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type")
        request.httpBody = try! createBody(with: parameters, files: files, boundary: boundary)
         
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        let uploadTask = session.dataTask(with: request, completionHandler: {
            (data, response, error) -> Void in

            if error != nil{
                print(error!)
            }else{
                let str = String(data: data!, encoding: String.Encoding.utf8)
                print("--- upload success --- \n\(str!) \n")
            }
        })
        
        uploadTask.resume()
    }

    private func createBody(with parameters: [String: String]?,
                            files: [(name:String, path:String)],
                            boundary: String) throws -> Data {
        var body = Data()
         
        if parameters != nil {
            for (key, value) in parameters! {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
                body.append("\(value)\r\n")
            }
        }
         
        for file in files {
            let url = URL(fileURLWithPath: file.path)
            let filename = url.lastPathComponent
            let data = try Data(contentsOf: url)
            let mimetype = mimeType(pathExtension: url.pathExtension)
             
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; "
                + "name=\"\(file.name)\"; filename=\"\(filename)\"\r\n")
            body.append("Content-Type: \(mimetype)\r\n\r\n")
            body.append(data)
            body.append("\r\n")
        }
         
        body.append("--\(boundary)--\r\n")
        return body
    }
     
    func mimeType(pathExtension: String) -> String {
        if let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                           pathExtension as NSString,
                                                           nil)?.takeRetainedValue() {
            if let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?
                .takeRetainedValue() {
                return mimetype as String
            }
        }
        return "application/octet-stream"
    }
}

extension Data {
    
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}

extension ViewController: URLSessionDelegate, URLSessionTaskDelegate {

    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didSendBodyData bytesSent: Int64, totalBytesSent: Int64,
                    totalBytesExpectedToSend: Int64) {

        let pro = Float(totalBytesSent) / Float(totalBytesExpectedToSend)
        
        DispatchQueue.main.async {
            self.progressView.progress = pro
        }
        print("upload progress：\(pro)")
    }
}

