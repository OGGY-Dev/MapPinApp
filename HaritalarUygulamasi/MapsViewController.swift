//
//  ViewController.swift
//  HaritalarUygulamasi
//
//  Created by Oğulcan DEMİRTAŞ on 10.08.2021.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {

    @IBOutlet weak var isimTextField: UITextField!
    @IBOutlet weak var notTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    var locationManager = CLLocationManager()
    var secilenLatitude = Double()
    var secilenLongitude = Double()
    
    var secilenIsim = ""
    var secilenId : UUID?
    var annotationTitle = ""
    var annotationSubTitle = ""
    var annotationLatitude = Double ()
    var annotationLongitude = Double ()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization() //kullanıcıdan konumunu kullanabilmek için izin istiyoruz (uygulamayı kullanırken)
        locationManager.startUpdatingLocation()      //şuana kadar kullanıcının konumunu almış olduk - konumla ilgili ne yapacağımızı burdan sonra yazıcaz
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(konumSec(gestureRecognizer:))) // uzun basma jest algılayıcıyı  ayarladık
        
        gestureRecognizer.minimumPressDuration = 1     //kaç saniye basılı tutunca algılayacağını yazdık - 3 sn
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if secilenIsim != "" {
            // secilen isim boş değilse core data'dan verileri çek
            
            if let uuidString = secilenId?.uuidString {
                
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Yer")
                fetchRequest.predicate = NSPredicate(format: "id = %@", uuidString)
                fetchRequest.returnsObjectsAsFaults = false
                
                do{
                    let sonuclar = try context.fetch(fetchRequest)
                    
                    if sonuclar.count > 0 {        //verileri filtreleme işlemi yapıyoruz
                        
                        for sonuc in sonuclar as! [NSManagedObject] {
                            
                            if let isim = sonuc.value(forKey: "isim") as? String{
                                annotationTitle = isim
                                
                                if let not = sonuc.value(forKey: "not") as? String{
                                    annotationSubTitle = not
                                    
                                    if let latitude = sonuc.value(forKey: "latitude") as? Double{
                                        annotationLatitude = latitude
                                    
                                        if let longitude = sonuc.value(forKey: "longitude") as? Double{
                                            annotationLongitude = longitude
                                            
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubTitle
                                            
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            isimTextField.text = annotationTitle
                                            notTextField.text = annotationSubTitle
                                            locationManager.stopUpdatingLocation()
                                            let  span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                        
                                    }
                                    
                                }
                                
                            }
                            
                            
                            
                        }
                        
                    }
                    
                }catch{
                    print("hata")
                }
                
            }
            
        }else {
            //yeni veri eklemeye geldi
        }
        
    }
    //pin görünümünü aşağıda değiştiriyoruz
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseID = "benim annotationum"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .brown
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        }else{
            pinView?.annotation = annotation
        }
        return pinView
    }
// callouttan navigasyona geçme işlemi aşağıda yapıldı
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
      
        if secilenIsim != "" {
            
            let requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            
            CLGeocoder().reverseGeocodeLocation(requestLocation) { placemarkDizisi, hata in
                
                if let placemarks = placemarkDizisi {
                    if placemarks.count > 0 {
                        
                        let yeniPlacemark = MKPlacemark(placemark: placemarks[0])   //harita ögesi oluşturduk 
                        let item = MKMapItem(placemark: yeniPlacemark)
                        item.name = self.annotationTitle
                        
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]  //navigasyonun çalıştırma seçeneklerini ayarlıyoruz (arabayla sürüş) kullanıcı bunu kullandıktan sonra değiştirebiliyor
                        
                        item.openInMaps(launchOptions: launchOptions)
                        
                    }
                }
                
              
                
                
            }
            
        }
    }
    
    
    
    
    //kullanıcının seçtiği konum için yazılan fonksiyona yukarıdaki gestureRecognizerı entegre ediyoruz birlikte çalışması için
    //genel olarak dokunulan yeri kkordinata çevirip oraya pin koyduk
    
    @objc func konumSec(gestureRecognizer : UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {     //jest algılayıcı başladığında demek
             
            let dokunulanNokta = gestureRecognizer.location(in: mapView)    //mapview'da dokunulduğu nokta
            let dokunulanKoordinat = mapView.convert(dokunulanNokta, toCoordinateFrom : mapView)  // yukada dokunulan noktayı koordinata çevirdi
            
            secilenLatitude = dokunulanKoordinat.latitude
            secilenLongitude = dokunulanKoordinat.longitude
            
            let annotation = MKPointAnnotation()    //pin ' i tanımladık
            annotation.coordinate = dokunulanKoordinat  //pin'i dokunulan koordinata koydurduk
            annotation.title = isimTextField.text
            annotation.subtitle = notTextField.text
            
            mapView.addAnnotation(annotation)
            
            
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
       // print(locations[0].coordinate.latitude)   // enlem koordinatı***
       // print(locations[0].coordinate.longitude)   //boylam koordinatı***
        if secilenIsim == "" {
        let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude) //direk   koordinatları enlem ve boylam olarak aldık
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)  //seçtiğimiz bölgenin nasıl gösterileceğinin boyutları
        let region = MKCoordinateRegion(center: location, span: span) //bölgeyi seçiyoruz
        mapView.setRegion(region, animated: true)
        }
        // bu fonksiyonun anlamı şu - her koordinat güncellemesi olduğunda haritayı güncelle demek
    }
    
    
    @IBAction func kaydetTiklandi(_ sender: Any) {
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate    //appdelegate tanımlandı
        let context = appDelegate.persistentContainer.viewContext  //context'i appdelegateden çağırdık tanımladık
        //core data'yı import edip verileri coredatadan çekmeye başlıyoruz
        let yeniYer  = NSEntityDescription.insertNewObject(forEntityName: "Yer", into: context)
        
        yeniYer.setValue(isimTextField.text, forKey: "isim")
        yeniYer.setValue(notTextField.text, forKey: "not")
        yeniYer.setValue(secilenLatitude, forKey: "latitude")
        yeniYer.setValue(secilenLongitude, forKey: "longitude")
        yeniYer.setValue(UUID(), forKey: "id")
        
        
        do{
            try context.save()
            print("kayıt edildi")
            
        } catch{
            print("hata var")
        }
        NotificationCenter.default.post(name: NSNotification.Name("Yeni Yer Oluşturuldu"), object: nil)
        navigationController?.popViewController(animated: true)
    
    }
    

}

