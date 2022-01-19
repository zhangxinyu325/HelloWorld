//
//  ViewController.swift
//  LearnedDemo2
//
//  Created by bytedance on 2022/1/10.
//

import UIKit
import CoreImage
import Photos
class ViewController: UIViewController ,UINavigationControllerDelegate,UIImagePickerControllerDelegate{
        var ifHaveLvjing = 0
        var number = 0
        var dataSourceList = [UIImage]()

        var CIFilterNames = [ "CIPhotoEffectChrome",
                              "CIPhotoEffectFade",
                              "CIPhotoEffectInstant",
                              "CIPhotoEffectNoir",
                              "CIPhotoEffectProcess",
                              "CIPhotoEffectTonal",
                              "CIPhotoEffectTransfer",
                              "CISepiaTone"
                            ]
    var imageClipperView:ImageClipperView?=nil//裁剪框
    @IBOutlet var scrollView: UIScrollView!//滤镜效果框
    @IBOutlet weak var iamageToFilter: UIImageView!
    private var lastDistance:CGFloat = 0.0
    var takingPicture:UIImagePickerController!
    var pictureFrame:frameStruct?//存储导入图片坐标
    var pictureRect:CGRect? = nil//图片的聚矩形信息
    var theFirstImage:UIImage? = nil//存储每次导入的图片最开始
//    @IBOutlet var saturationSlider:UISlider? = nil
//    @IBOutlet var brightnessSlider:UISlider? = nil
    var briPicture:UIImage? = nil
    var satPicture:UIImage? = nil
    var conPictre :UIImage? = nil
    var compareButton=UIButton()
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        view.backgroundColor = UIColor.darkGray
        // imageView.backgroundColor=UIColor.white
        //导入的图片周围设置阴影
        self.imageView.layer.shadowOpacity=2
        self.imageView.layer.shadowColor=UIColor.black.cgColor
        self.imageView.layer.shadowOffset=CGSize(width: 1, height: 1)
        //触摸放大
        self.view.isMultipleTouchEnabled = true
        //捏合图片
        //首先要允许视图的交互属性为真，使视图可以接收触摸事件
        imageView.isUserInteractionEnabled = true
        //初始化一个捏合手势，并给手势绑定触发事件
        let gesture=UIPinchGestureRecognizer(target: self, action: #selector(pinchImage(_:)))
        //将手势添加到视图上
        imageView.addGestureRecognizer(gesture)
        
        compareButton.frame=CGRect(x: 295, y: 636, width: 83, height: 36)
        compareButton.backgroundColor=UIColor.black
        compareButton.setTitle("对比原图", for: .normal)
        compareButton.setTitleColor(UIColor.white, for: .normal)
        compareButton.isEnabled=true
        compareButton.addTarget(self, action: #selector(touchDown(_:)), for: .touchDown)
        compareButton.addTarget(self, action: #selector(touchInside(_:)), for: .touchUpInside)
        self.view.addSubview(compareButton)
    }
    var theComparePicture=UIImage()
    @objc func touchDown(_ sender:UIButton){
        theComparePicture=imageView.image!
        imageView.image=theFirstImage
    }
    @objc func touchInside(_ sender:UIButton){
        
        imageView.image=theComparePicture
        
    }
    //获取图片
    @IBAction func takrPicture(_ sender: UIButton) {
        let actionSheet=UIAlertController()//弹窗选项
        let cancleAction=UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel,
                                       handler: {(alertAction)->Void in print("取消")})
        let cameraPicture=UIAlertAction(title: "从相机选择", style: UIAlertAction.Style.destructive, handler: {(alterAction)->Void in
            self.getPicture(Type: 1)
        })
        let libraryPicture=UIAlertAction(title: "图库选择", style: UIAlertAction.Style.default, handler: {(alterAction)->Void in
            self.getPicture(Type: 2)
        })
        
        actionSheet.addAction(cancleAction)
        actionSheet.addAction(cameraPicture)
        actionSheet.addAction(libraryPicture)
        
        present(actionSheet,animated: true,completion: nil)
        if ifHaveLvjing == 1{
            
        }
        ifHaveLvjing = 0
        if ifChange == 1{
            brightnessSlider.value=0
            saturationSlider.value=0
            contrastSlider.value=0
        }
    }
    var imageIndex = UIImage()
    //滤镜按钮
    var selfFilter:CIFilter? = nil
    @IBAction func blackWhiteChange(_ sender: UIButton) {
        //imageView.image=imageIndex.blackAndWhite()
        //内置一行按钮的坐标
        if (imageView.image != nil && ifHaveLvjing == 0){
        var xCoord: CGFloat = 5
        let yCoord: CGFloat = 5
        let buttonWidth:CGFloat = 70
        let buttonHeight: CGFloat = 70
        let gapBetweenButtons: CGFloat = 5

        //设置滤镜显示框和滤镜按钮
        var itemCount=0
        for i in 0..<CIFilterNames.count{
            itemCount=i
            let filterButton = UIButton(type: .custom)
            filterButton.frame = CGRect(x: xCoord, y: yCoord, width: buttonWidth, height: buttonHeight)
                    filterButton.tag = itemCount
            filterButton.addTarget(self, action: #selector(filterButtonTapped(sender:)), for: .touchUpInside)
                    filterButton.layer.cornerRadius = 6
                    filterButton.clipsToBounds = true
            let ciContext = CIContext(options: nil)
            let coreImage = CIImage(image: theFirstImage!)
            let filter = CIFilter(name: "\(CIFilterNames[i])" )
            filter!.setDefaults()
            filter!.setValue(coreImage, forKey: kCIInputImageKey)
            let filteredImageData = filter!.value(forKey: kCIOutputImageKey) as! CIImage
            let filteredImageRef = ciContext.createCGImage(filteredImageData, from: filteredImageData.extent)as! CGImage
            let imageForButton = UIImage(cgImage: filteredImageRef)
            filterButton.setBackgroundImage(imageForButton, for: .normal)
            xCoord += buttonWidth + gapBetweenButtons
            scrollView.addSubview(filterButton)
        }
        //设置滤镜显示框的大小
            scrollView.contentSize = CGSize(width: buttonWidth*CGFloat(itemCount+2), height: yCoord)
            ifHaveLvjing=1
        }
    }
    //旋转图片
    @IBAction func rotatePicture(_ sender: UIButton) {
        if (imageView.image != nil){
            let newImage=imageView.image?.rotate(radians: .pi/2)
            imageView.image=newImage
        }
    }
    var changeIndex=0
    //裁剪图片
    @IBAction func clipperPicture(_ sender: UIButton) {
////        imageClipperView=ImageClipperView(frame: CGRect(x: 0, y: 20, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height-40),image: imageView.image!)
////        self.imageView.addSubview(imageClipperView!)
//        pictureRect=calculateRectOfImageInImageView(imageView: imageView)//获取图片后就将矩形信息传出
//        var image = imageView.image
//        imageClipperView = ImageClipperView(frame: CGRect(x: 20, y: 111, width: 356, height: 408))
//        print("test")
////        let clipperRect:ImageClipperRect = ImageClipperRect(frame:pictureRect!)
////        self.view.addSubview(clipperRect)
        var imageIndex=UIImage()
        if(imageView.image != nil){
            if changeIndex==0{
                imageIndex=(imageView.image?.cropToSquare())!
                imageView.image=imageIndex
                changeIndex+=1
            }else if changeIndex==1{
                imageView.image=theFirstImage
                changeIndex=0
            }
        }
    }
    //圆角图形
    @IBAction func changePicture2(_ sender: UIButton) {
        var imageIndex=UIImage()
        if (imageView.image != nil){
            imageIndex=(imageView.image?.roundCorners(cornerRadius: 200))!
            imageView.image=imageIndex
        }
    }
    //圆形图片
    @IBAction func circleChange(_ sender: UIButton) {
        var imageIndex=UIImage()
        if (imageView.image != nil){
            imageIndex=(imageView.image?.roundCornersToCircle())!
            imageView.image=imageIndex
        }
    }
    //恢复原样
    @IBAction func cancleChange(_ sender: UIButton) {
        if (imageView.image != nil){
            imageView.image=theFirstImage
            brightnessSlider.value=0
            saturationSlider.value=0
            contrastSlider.value=0
            theIndexImage=theFirstImage!
        }
    }
    //将修改后的图片保存
    @IBAction func savePicture(_ sender: UIButton) {
        //保存至本地-可以正常运行
//        if(imageView.image != nil){
//            let savedPictureName=String.randomStr(len: 10)
//            let actionSheet = UIAlertController()//弹窗选项
//            let cancleAction=UIAlertAction(title: "取消", style: UIAlertAction.Style.cancel,
//                                           handler: {(alertAction)->Void in print("取消")})
//            let save=UIAlertAction(title: "确认保存", style: UIAlertAction.Style.destructive, handler: {(alterAction)->Void in
//
//                self.saveImage(image: self.imageView.image!)
//            })
//            actionSheet.addAction(cancleAction)
//            actionSheet.addAction(save)
//            present(actionSheet,animated: true,completion: nil)
//        }
//      UIImageWriteToSavedPhotosAlbum(iamageToFilter.image!, nil, nil, nil)
        if(imageView.image != nil){
            self.saveImage(image: self.imageView.image)
        }
        
    }
    func saveImage(image: UIImage) {
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.creationRequestForAsset(from: image)
        }) { (isSuccess, error) in
            print("\(isSuccess)----\(String(describing: error))")
        }
    }
    var brightness:Int = 0//记录图片的亮度值
    var saturation:Int = 0//饱和度值
    var contrast:Int = 0//对比度值
    var ifChange=0
    var brightnessSlider=UISlider()
    var saturationSlider=UISlider()
    var contrastSlider=UISlider()
    var theIndexImage=UIImage()
    //调节图片亮度，对比度，饱和度
    @IBAction func changePicture(_ sender: UIButton) {
      if(imageView.image != nil && ifChange==0){
        var brightnessLabel=UILabel()
        var saturationLabel=UILabel()
        var contrastLabel=UILabel()
        brightnessLabel.textColor = UIColor.white
        saturationLabel.textColor = UIColor.white
        contrastLabel.textColor = UIColor.white
        brightnessLabel.text="亮度"
        saturationLabel.text="饱和度"
        contrastLabel.text="对比度"
        brightnessLabel.frame=CGRect(x: 22, y: 702, width: 42, height: 21)
        saturationLabel.frame=CGRect(x: 22, y: 738, width: 60, height: 21)
        contrastLabel.frame=CGRect(x: 22, y: 773, width: 60, height: 21)
        self.view.addSubview(brightnessLabel)
        self.view.addSubview(saturationLabel)
        self.view.addSubview(contrastLabel)
        brightnessSlider.frame=CGRect(x: 108, y: 695, width: 270, height: 30)
        brightnessSlider.minimumValue = -1
        brightnessSlider.maximumValue=1
          brightnessSlider.value=0
        brightnessSlider.isContinuous=false
        saturationSlider.frame=CGRect(x: 108, y: 732, width: 270, height: 30)
        saturationSlider.minimumValue = -1
        saturationSlider.maximumValue=1
          saturationSlider.value=0
        saturationSlider.isContinuous=false
        contrastSlider.frame=CGRect(x: 108, y: 769, width: 270, height: 30)
        contrastSlider.minimumValue = -1
        contrastSlider.maximumValue=1
          contrastSlider.value=0
        contrastSlider.isContinuous=false
        self.view.addSubview(brightnessSlider)
        self.view.addSubview(saturationSlider)
        self.view.addSubview(contrastSlider)
        brightnessSlider.addTarget(self, action: #selector(brightnessChange(_:)), for: .valueChanged)
        saturationSlider.addTarget(self, action:#selector(saturationChange(_:)), for: .valueChanged)
          contrastSlider.addTarget(self, action: #selector(contrastChange(_:)), for: .valueChanged)
          theIndexImage=imageView.image!
        ifChange=1
      }
        
    }
    //修改图片亮度
    var theChangePicture=UIImage()
    @objc func brightnessChange(_ sender: UISlider){
        let context=CIContext(options: nil)
        let ciimage=CIImage(image: theIndexImage)
        let filter=CIFilter(name: "CIColorControls")
        filter?.setValue(ciimage, forKey: kCIInputImageKey)
        filter!.setValue(sender.value, forKey:kCIInputBrightnessKey)
        var imageOut=filter?.outputImage
        let imageRef=context.createCGImage(imageOut!, from: imageOut!.extent )as! CGImage
        let uiImage=UIImage(cgImage: imageRef)
        imageView.image=uiImage
        briPicture=imageView.image
        theIndexImage=imageView.image!
    }//修改图片饱和度
    @objc func saturationChange(_ sender:UISlider){
        let context=CIContext(options: nil)
        let ciimage=CIImage(image: briPicture!)
        let filter=CIFilter(name: "CIColorControls")
        filter?.setValue(ciimage, forKey: kCIInputImageKey)
        filter!.setValue(sender.value, forKey:kCIInputSaturationKey)
        let imageOut=filter?.outputImage
        let imageRef=context.createCGImage(imageOut!, from: imageOut!.extent )as! CGImage
        let uiImage=UIImage(cgImage: imageRef)
        imageView.image=uiImage
        satPicture=imageView.image
        theIndexImage=imageView.image!
    }
    //修改图片对比度
    @objc func contrastChange(_ sender:UISlider){
        let context=CIContext(options: nil)
        let ciimage=CIImage(image: satPicture!)
        let filter=CIFilter(name: "CIColorControls")
        filter?.setValue(ciimage, forKey: kCIInputImageKey)
        filter!.setValue(sender.value, forKey:kCIInputContrastKey)
        let imageOut=filter?.outputImage
        let imageRef=context.createCGImage(imageOut!, from: imageOut!.extent )as! CGImage
        let uiImage=UIImage(cgImage: imageRef)
        imageView.image=uiImage
        theIndexImage=imageView.image!
    }
    //保存图片
//    @objc func saveImage(image: UIImage, imageName: String) {
//        let imageData = image.pngData()
//        let imagePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first! + "/\(imageName).png"
//            print("\(imagePath)")
//        do{
//                try! imageData?.write(to: URL(fileURLWithPath: imagePath))
//        }
//    }
    
    @IBOutlet var imageView: UIImageView!
    
    //捏合手势的调用方法
    @objc func pinchImage(_ recognizer:UIPinchGestureRecognizer){
        //根据捏合手势器的缩放比例，调整视图的比例
        recognizer.view?.transform=(recognizer.view?.transform.scaledBy(x: recognizer.scale, y: recognizer.scale))!
        //恢复捏合手势识别器的初始比例
        //每次缩放都从百分之百比例进行
        recognizer.scale=1
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
   @objc func filterButtonTapped(sender: UIButton) {
        let button = sender as UIButton
            
        imageView.image = button.backgroundImage(for: .normal)
    }
    //获取图片
    func getPicture(Type:Int){
        takingPicture = UIImagePickerController.init()
        if Type == 1{
            takingPicture.sourceType = .camera
        }else if Type == 2{
            takingPicture.sourceType = .photoLibrary
        }
        takingPicture.allowsEditing=false
        takingPicture.delegate=self
        present(takingPicture,animated: true,completion: nil)
    }
    //保存返回的图片
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let image=info[UIImagePickerController.InfoKey.originalImage]as!UIImage
        imageView.image=image
        theFirstImage=image
        briPicture=theFirstImage
        satPicture=theFirstImage
        conPictre=theFirstImage
        dismiss(animated: true, completion: nil)
        }
    //获取图片的坐标
    func calculateRectOfImageInImageView(imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.frame.size
        let imgSize = imageView.image?.size

        guard let imageSize = imgSize, imgSize != nil else {
            return CGRect.zero
        }

        let scaleWidth = imageViewSize.width / imageSize.width
        let scaleHeight = imageViewSize.height / imageSize.height
        let aspect = fmin(scaleWidth, scaleHeight)

        var imageRect = CGRect(x: 0, y: 0, width: imageSize.width * aspect, height: imageSize.height * aspect)
        // Center image
        imageRect.origin.x = (imageViewSize.width - imageRect.size.width) / 2
        imageRect.origin.y = (imageViewSize.height - imageRect.size.height) / 2

        // Add imageView offset
        imageRect.origin.x += imageView.frame.origin.x
        imageRect.origin.y += imageView.frame.origin.y

        return imageRect
    }
    func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage?
    {
        let imageViewScale = max(inputImage.size.width / viewWidth,
                                 inputImage.size.height / viewHeight)
        // Scale cropRect to handle images larger than shown-on-screen size
        let cropZone = CGRect(x:cropRect.origin.x * imageViewScale,
                              y:cropRect.origin.y * imageViewScale,
                              width:cropRect.size.width * imageViewScale,
                              height:cropRect.size.height * imageViewScale)
        // Perform cropping in Core Graphics
        guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to:cropZone)
        else {
            return nil
        }
        // Return image to UIImage
        let croppedImage: UIImage = UIImage(cgImage: cutImageRef)
        return croppedImage
    }
}
