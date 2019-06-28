//
//  ViewController.swift
//  PDF Annotations
//
//  Created by Junnosuke Nakamura on 6/14/19.
//  Copyright © 2019 Appkey. All rights reserved.
//

import UIKit
import PDFKit
import Alamofire
import Toast_Swift

class ViewController: UIViewController {
    
    @IBOutlet weak var pdfView: PDFView!
    @IBOutlet weak var thumbnailView: PDFThumbnailView!
    
    @IBOutlet weak var penButton: UIButton!
    @IBOutlet weak var handButton: UIButton!
    @IBOutlet weak var pencilButton: UIButton!
    @IBOutlet weak var markerButton: UIButton!
    @IBOutlet weak var eraserButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    @IBOutlet weak var indicatorDownloadFile: UIActivityIndicatorView!
    
    @IBOutlet weak var colorIndicator: ColorPalette!
    @IBOutlet weak var colorPalettesView: UIView!
    @IBOutlet weak var redColor: UIButton!
    @IBOutlet weak var yellowColor: UIButton!
    @IBOutlet weak var greenColor: UIButton!
    
    private var shouldUpdatePDFScrollPosition = true
    private let pdfDrawer = PDFDrawer()
    private let gesture = DrawingGestureRecognizer()
    
    var selectedColor:UIColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1) //default color is red

    var fileURL:URL?
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        shouldUpdatePDFScrollPosition = false
        setupLoad()
    }
    
    func setupLoad(){
        //Prepare PDF View & Thumbnail View
        initComponent()
        
        //Configure Edit's tools & Gestures
        configureTools()
        configureGesture()
        
        //Download PDF File
        indicatorDownloadFile.startAnimating()
        indicatorDownloadFile.isHidden = false
        downloadPDF()
        
        //Set default tools on first load
        changeTools(tool: "hand")
        penButton.isSelected = false
        pencilButton.isSelected = false
        markerButton.isSelected = false
        eraserButton.isSelected = false
        handButton.isSelected = true
        
        //Indicator save pdf
        indicatorSave(show: false)
    }
    
    func initComponent(){
        pdfView.displayDirection = .horizontal
        pdfView.usePageViewController(true)
        pdfView.pageBreakMargins = UIEdgeInsets(top: 0,left: 0,bottom: 0,right: 0)
        pdfView.autoScales = true
        
        thumbnailView.pdfView = pdfView
        thumbnailView.thumbnailSize = CGSize(width: 25, height: 50)
        thumbnailView.layoutMode = .horizontal
        thumbnailView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
    }
    
    func loadFiles(url: URL){
        if url.absoluteString != "" {
            pdfView.document = PDFDocument(url: url)
            pdfView.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        } else {
            print("url is empty")
        }
        
    }
    
    func configureGesture(){
        gesture.drawingDelegate = pdfDrawer
        pdfDrawer.pdfView = pdfView
        pdfDrawer.color = selectedColor
    }
    
    func configureTools() {
        //set collor palette hidden for default
        colorIndicator.backgroundColor = selectedColor
        colorPalettesView.isHidden = true
        redColor.isSelected = true
        
        //set tools icon
        penButton.setImage(UIImage(named: "pen-outline"), for: .normal)
        penButton.setImage(UIImage(named: "pen-filled"), for: .selected)
        pencilButton.setImage(UIImage(named: "pencil-outline"), for: .normal)
        pencilButton.setImage(UIImage(named: "pencil-filled"), for: .selected)
        markerButton.setImage(UIImage(named: "marker-outline"), for: .normal)
        markerButton.setImage(UIImage(named: "marker-filled"), for: .selected)
        eraserButton.setImage(UIImage(named: "eraser-outline"), for: .normal)
        eraserButton.setImage(UIImage(named: "eraser-filled"), for: .selected)
        handButton.setImage(UIImage(named: "hand-outline"), for: .normal)
        handButton.setImage(UIImage(named: "hand-filled"), for: .selected)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if shouldUpdatePDFScrollPosition {
            fixPDFViewScrollPosition()
        }
    }
    
    private func fixPDFViewScrollPosition(){
        if let page = pdfView.document?.page(at: 0){
            pdfView.go(to: PDFDestination(page: page, at: CGPoint(x: 0, y: page.bounds(for: pdfView.displayBox).size.height)))
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        pdfView.autoScales = true
    }
    
    @IBAction func changeToDraw(_ sender: Any) {
        changeTools(tool: "pen")
        penButton.isSelected = true
        pencilButton.isSelected = false
        markerButton.isSelected = false
        eraserButton.isSelected = false
        handButton.isSelected = false
    }
    @IBAction func changeToPencil(_ sender: Any) {
        changeTools(tool: "pencil")
        penButton.isSelected = false
        pencilButton.isSelected = true
        markerButton.isSelected = false
        eraserButton.isSelected = false
        handButton.isSelected = false
    }
    @IBAction func changeToMaker(_ sender: Any) {
        changeTools(tool: "marker")
        penButton.isSelected = false
        pencilButton.isSelected = false
        markerButton.isSelected = true
        eraserButton.isSelected = false
        handButton.isSelected = false
    }
    @IBAction func changeToEraser(_ sender: Any) {
        changeTools(tool: "eraser")
        penButton.isSelected = false
        pencilButton.isSelected = false
        markerButton.isSelected = false
        eraserButton.isSelected = true
        handButton.isSelected = false
    }
    @IBAction func changeToScroll(_ sender: Any) {
        changeTools(tool: "hand")
        penButton.isSelected = false
        pencilButton.isSelected = false
        markerButton.isSelected = false
        eraserButton.isSelected = false
        handButton.isSelected = true
        
    }
    
    @IBAction func showColorPalettes(_ sender: Any) {
        togglePalettes()
    }
    
    @IBAction func savePDF(_ sender: Any) {
        //Save to file
        indicatorSave(show: true)
        guard let data = pdfView.document?.dataRepresentation() else {return}
        
        do {
            try data.write(to: self.fileURL!)
            indicatorSave(show: false)
            self.view.makeToast("Saved.")
        } catch {
            print(error.localizedDescription)
            indicatorSave(show: false)
            self.view.makeToast("Failed.")
        }
    }
    
    func indicatorSave(show:Bool){
        indicator.startAnimating()
        if show {
            indicator.isHidden = false
            saveButton.isHidden = true
        }else{
            indicator.isHidden = true
            saveButton.isHidden = false
        }
    }
    
    func changeTools(tool: String){
        switch tool{
            case "pen":
                pdfView.addGestureRecognizer(gesture)
                pdfDrawer.drawingTool = .pen
            case "pencil":
                pdfView.addGestureRecognizer(gesture)
                pdfDrawer.drawingTool = .pencil
            case "marker":
                pdfView.addGestureRecognizer(gesture)
                pdfDrawer.drawingTool = .highlighter
            case "eraser":
                pdfView.addGestureRecognizer(gesture)
                pdfDrawer.drawingTool = .eraser
            default:
                pdfView.removeGestureRecognizer(gesture)
        }
    }
    
    func togglePalettes(){
        if colorPalettesView.isHidden == true {
            self.colorPalettesView.alpha = 0.0
            self.colorPalettesView.isHidden = false
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                self.colorPalettesView.alpha = 1.0
            }) { (isCompleted) in
            }
        } else{
            UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut, animations: {
                self.colorPalettesView.alpha = 0.0
            }) { (isCompleted) in
                self.colorPalettesView.isHidden = true
            }
        }
    }
    
    //color selected sections
    @IBAction func redSelected(_ sender: Any) {
        selectedColor = UIColor(red: 231/255, green: 76/255, blue: 60/255, alpha: 1)
        colorIndicator.backgroundColor = selectedColor
        pdfDrawer.color = selectedColor
        redColor.isSelected = true
        yellowColor.isSelected = false
        greenColor.isSelected = false
        
        togglePalettes() // it will hidden the palettes
    }
    @IBAction func yellowSelected(_ sender: Any) {
        selectedColor = UIColor(red: 241/255, green: 196/255, blue: 15/255, alpha: 1)
        colorIndicator.backgroundColor = selectedColor
        pdfDrawer.color = selectedColor
        redColor.isSelected = false
        yellowColor.isSelected = true
        greenColor.isSelected = false
        
        togglePalettes()
    }
    @IBAction func greenSelected(_ sender: Any) {
        selectedColor = UIColor(red: 46/255, green: 204/255, blue: 113/255, alpha: 1)
        colorIndicator.backgroundColor = selectedColor
        pdfDrawer.color = selectedColor
        redColor.isSelected = false
        yellowColor.isSelected = false
        greenColor.isSelected = true
        
        togglePalettes()
    }
    func getDirectoryPath() -> String {
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        return paths[0]
        
    }
    func downloadPDF(){
        // path destination for Download
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.fileURL = documentsURL.appendingPathComponent("your.pdf")
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            return (self.fileURL!, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        //path pdf for check
        let pdfPath = (self.getDirectoryPath() as NSString).appendingPathComponent("your.pdf")
        
        if FileManager.default.fileExists(atPath: pdfPath){
            print("File already exists.")
            // load pdf downloaded
            self.loadFiles(url: self.fileURL!)
            self.indicatorDownloadFile.isHidden = true
            
        }else{
            print("File not found.")
            self.view.makeToast("File not found, Downloading file.")
            
            let urlDownload = URL(string: "https://www.ets.org/Media/Tests/TOEFL/pdf/SampleQuestions.pdf")
            Alamofire.download(urlDownload!, to: destination).response { response in
                if response.error == nil, let _ = response.destinationURL?.path {
                    print(response.destinationURL?.path as Any)
                    
                    // load pdf downloaded
                    self.loadFiles(url: self.fileURL!)
                    self.indicatorDownloadFile.isHidden = true
                }
            }
            
        }
        
        
    }
    
}

