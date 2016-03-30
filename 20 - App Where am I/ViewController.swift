//
//  ViewController.swift
//  20 - App Where am I
//
//  Created by Marco Linhares on 6/27/15.
//  Copyright (c) 2015 Marco Linhares. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    var manager = CLLocationManager()
    var centered = true
    var endereco : String = ""

    // cria uma anotação a ser colocada no mapa
    var annotation = MKPointAnnotation ()

    @IBOutlet weak var labelError: UILabel!
    
    @IBOutlet weak var map: MKMapView!
    
    @IBAction func buttonInfo(sender: AnyObject) {
        // view que contém as informações extras
        (view.viewWithTag (10) as UIView?)!.hidden = false
    }
    
    @IBAction func buttonBack(sender: AnyObject) {
        (view.viewWithTag (10) as UIView?)!.hidden = true
    }
    
    // troca o valor da variável centered
    @IBAction func buttonCenter(sender: AnyObject) {
        if centered == true {
            
            centered = false
            sender.setTitle ("Center OFF", forState: UIControlState.Normal)
            
        } else {
            
            centered = true
            sender.setTitle ("Center ON", forState: UIControlState.Normal)
            
        }
    }
    
    // função que é chamada toda vez que a localização for atualizada
    func locationManager (manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        
        var userLocation : CLLocation = locations[0] as! CLLocation
        
        var lat = userLocation.coordinate.latitude
        var lon = userLocation.coordinate.longitude
        
        var myLocation: CLLocationCoordinate2D
        
        labelError.text = ""
        
        if centered == true {
            // desenha um novo mapa com a pessoa centralizada
            myLocation = createMap (map, latitude: lat, longitude: lon, delta: 0.01)
        } else {
            // caso não precise centralizar, então pode ser usado o mapa anterior e não
            // é preciso criar um novo mapa. apenas é passada a posição atual da pessoa
            myLocation = CLLocationCoordinate2DMake (lat, lon)
        }

        // remove a anotação anterior. na 1a vez que é executado, não acontece nada
        map.removeAnnotation(annotation)
        
        createAnnotation (map, location: myLocation, title: "Sou eu", subtitle: "Estou aqui")
        
        // label latitude
        (view.viewWithTag (1) as! UILabel?)!.text = String(format: "%.2f", lat)

        // label longitude
        (view.viewWithTag (2) as! UILabel?)!.text = String(format: "%.2f", lon)

        // label direção
        (view.viewWithTag (3) as! UILabel?)!.text = String(format: "%.2f", userLocation.course)

        // label velocidade
        (view.viewWithTag (4) as! UILabel?)!.text = String(format: "%.1f km/h", userLocation.speed * 3.6)
        
        // label altitude
        (view.viewWithTag (5) as! UILabel?)!.text = String(format: "%.2f m", userLocation.altitude)
        
        // preenche a variável global endereco
        getGeolocalization (lat, longitude: lon)
        
        dispatch_async (dispatch_get_main_queue()) {
            // label endereço
            (self.view.viewWithTag (6) as! UILabel?)!.text = self.endereco
        }
    }
    
    // é chamada caso o GPS esteja desligado ou a pessoa não aceitou a permissão
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        labelError.text = "GPS sem sinal"
    }
    
    func createMap (map: MKMapView!, latitude : CLLocationDegrees, longitude : CLLocationDegrees, delta: CLLocationDegrees) -> CLLocationCoordinate2D {
        var lat : CLLocationDegrees = latitude
        var lon : CLLocationDegrees = longitude
        
        // quanto maior o número, maior o zoom. 1 é muito e 180 é o valor máximo que é o mundo inteiro
        var latDelta : CLLocationDegrees = delta
        var lonDelta : CLLocationDegrees = delta
        
        // cria a região desejada
        var span     : MKCoordinateSpan       = MKCoordinateSpanMake(latDelta, lonDelta)
        var location : CLLocationCoordinate2D = CLLocationCoordinate2DMake(lat, lon)
        
        // cria o mapa da região
        var region : MKCoordinateRegion = MKCoordinateRegionMake(location, span)
        
        // coloca a região e mostra no mapa
        map.setRegion(region, animated: true)
        
        return location
    }

    func createAnnotation (map: MKMapView!, location : CLLocationCoordinate2D, title : String, subtitle : String) {
        annotation.coordinate = location
        annotation.title      = title
        annotation.subtitle   = subtitle
        
        // coloca as anotações no mapa
        map.addAnnotation(annotation)
    }
    
    // pega o endereço através de geolocalização reversa
    func getGeolocalization (latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        var geocoder = CLGeocoder()
        var location = CLLocation(latitude: latitude, longitude: longitude)
        
        geocoder.reverseGeocodeLocation (location) {
            (placemarks, error) -> Void in
            if let placemarks = placemarks as? [CLPlacemark] where placemarks.count > 0 {
                var placemark = placemarks [0]
                
                if placemark.name != nil {
                    self.endereco = placemark.name + "\n"
                }
                
                if placemark.subLocality != nil {
                    self.endereco += "Bairro: " + placemark.subLocality + "\n"
                }
                
                if placemark.postalCode != nil {
                    self.endereco += "CEP: " + placemark.postalCode
                    
                    if placemark.addressDictionary ["PostCodeExtension"] != nil {
                        self.endereco += "-" + (placemark.addressDictionary ["PostCodeExtension"] as? String)!
                    }
                    
                    self.endereco += "\n"
                }
                
                if placemark.locality != nil && placemark.administrativeArea != nil {
                    self.endereco += placemark.locality + "/" + placemark.administrativeArea + "\n"
                }
                
                if placemark.country != nil {
                    self.endereco += placemark.country
                }
                
                self.endereco = self.endereco.stringByReplacingOccurrencesOfString ("Avenida",   withString: "Av.")
                self.endereco = self.endereco.stringByReplacingOccurrencesOfString ("Parque",    withString: "Pq.")
                self.endereco = self.endereco.stringByReplacingOccurrencesOfString ("Doutor",    withString: "Dr.")
                self.endereco = self.endereco.stringByReplacingOccurrencesOfString ("Professor", withString: "Prof.")
                
                //  cidade:         placemark.locality
                //  nome da rua:    placemark.thoroughfare
                //  rua e números:  placemark.name
                //  estado:         placemark.administrativeArea
                //  país:           placemark.country
                //  bairro:         placemark.subLocality
                //  CEP:            placemark.postalCode
                //
                // outros:
                //
                // número da rua:   placemark.subThoroughfare
                // nome da rua:     placemark.thoroughfare
                // bairro??:        placemark.subAdministrativeArea
                //
                // a linha que mostra todo o endereço é essa do println e abaixo a saída:
                // println (placemark.addressDictionary)
                //
                //[SubLocality:
                //    Parque das Universidades,
                //    CountryCode: BR,
                //    Street: Avenida Professor Doutor Zeferino Vaz, 21–119,
                //    State: SP,
                //    ZIP: 13086,
                //    Name: Avenida Professor Doutor Zeferino Vaz, 21–119,
                //    Thoroughfare: Avenida Professor Doutor Zeferino Vaz,
                //
                //    FormattedAddressLines: (
                //    "Avenida Professor Doutor Zeferino Vaz, 21\U2013119",
                //    "Parque das Universidades",
                //    "Campinas - SP",
                //    "13086-090",
                //    Brasil
                //    ), SubThoroughfare: 21–119,
                //    PostCodeExtension: 090,
                //    Country: Brasil,
                //    City: Campinas
                //]
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // coloca o delegate. é preciso fazer via código pois ele não é um elemento do storyboard. self = ViewController
        manager.delegate = self

        // quanto maior a acurácia, maior o gasto de bateria. use o menor possível
        manager.desiredAccuracy = kCLLocationAccuracyBest
        
        // faz o pedido para pegar a localização
        manager.requestWhenInUseAuthorization()
        
        manager.startUpdatingLocation()
        
        (view.viewWithTag (10) as UIView?)!.hidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

