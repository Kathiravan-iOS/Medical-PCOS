//
//  PcosCategory.swift
//  Pcos
//
//  Created by Karthik Babu on 05/10/23.
//

import UIKit

class PcosCategory: UIViewController {
    @IBOutlet weak var startButton: UIButton!

    var  username4 : String = ""
    var shouldHideStartButton: Bool = false
    var patientScoreData : PaitentScoreModel?
    override func viewDidLoad() {
        super.viewDidLoad()
        self.patientScoreAPI()
        if shouldHideStartButton {
                    // Assuming the "start" button is an IBOutlet named startButton
                    startButton.isHidden = true
                }
      

    }
    func progressBar() {
            // Assuming the PaitentScoreModel and its 'data' property have 'mild', 'moderate', and 'severe' fields.
        let ringPieChartSize: CGFloat = 200
            let ringPieChartX = (view.bounds.width - ringPieChartSize) / 2
            let ringPieChartY = (view.bounds.height - ringPieChartSize) / 2
            
            let ringPieChartView = UIView(frame: CGRect(x: ringPieChartX, y: ringPieChartY, width: ringPieChartSize, height: ringPieChartSize))
            view.addSubview(ringPieChartView)
        let mildScore = Double(patientScoreData?.data?.mild ?? 0)
        let moderateScore = Double(patientScoreData?.data?.moderate ?? 0)
        let severeScore = Double(patientScoreData?.data?.severe ?? 0)
            let dataPoints: [Double] = [mildScore, moderateScore, severeScore]
            let colors: [UIColor] = [
                UIColor(red: 102/255.0, green: 16/255.0, blue: 242/255.0, alpha: 1.0), // Purple
                UIColor(red: 255/255.0, green: 134/255.0, blue: 91/255.0, alpha: 1.0), // Orange
                UIColor(red: 52/255.0, green: 216/255.0, blue: 154/255.0, alpha: 1.0)  // Green
            ]
        
        // Calculate the total value of dataPoints
        let total = dataPoints.reduce(0, +)
        
        // Set up the starting angle for the sectors
        var startAngle: CGFloat = -CGFloat.pi / 2
        
        for (index, value) in dataPoints.enumerated() {
            // Calculate the angle for the current sector
            let angle = 2 * CGFloat.pi * CGFloat(value / total)
            
            // Create the outer path for the ring sector with a gap between sectors
            let gap: CGFloat = 0.05 // Adjust the gap size as needed
            let outerPath = UIBezierPath(arcCenter: CGPoint(x: ringPieChartView.bounds.midX, y: ringPieChartView.bounds.midY),
                                         radius: ringPieChartView.bounds.width / 2,
                                         startAngle: startAngle + gap / 2,
                                         endAngle: startAngle + angle - gap / 2,
                                         clockwise: true)
            
            // Create the inner path for the hole in the center
            let innerPath = UIBezierPath(arcCenter: CGPoint(x: ringPieChartView.bounds.midX, y: ringPieChartView.bounds.midY),
                                         radius: ringPieChartView.bounds.width / 4, // Adjust the inner radius as needed
                                         startAngle: startAngle + angle - gap / 2,
                                         endAngle: startAngle + gap / 2,
                                         clockwise: false)
            
            // Combine the outer and inner paths to create the ring sector
            outerPath.append(innerPath)
            
            // Create a shape layer for the ring sector
            let sectorLayer = CAShapeLayer()
            sectorLayer.path = outerPath.cgPath
            sectorLayer.strokeColor = colors[index].cgColor // Set stroke color
            sectorLayer.fillColor = UIColor.clear.cgColor // Clear fill color (to make it a ring)
            sectorLayer.lineWidth = ringPieChartView.bounds.width / 2 // Set line width
            
            // Add the sector layer to the ring pie chart view
            ringPieChartView.layer.addSublayer(sectorLayer)
            
            // Update the starting angle for the next sector, including the gap
            startAngle += angle
        }
        
        // Create a circle in the center
        let centerCircle = UIView(frame: CGRect(x: ringPieChartView.bounds.midX - ringPieChartView.bounds.width / 2, y: ringPieChartView.bounds.midY - ringPieChartView.bounds.width / 2, width: 200, height: 200))
        let pink =  UIColor(red: 255/255.0, green: 192/255.0, blue: 222/255.0, alpha: 1.0)
        
        centerCircle.backgroundColor = pink
        centerCircle.layer.cornerRadius = 100
        ringPieChartView.addSubview(centerCircle)
    }
    
    @IBAction func start(_ sender: Any) {
            if let patientVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "PatientPlanVC") as? PatientPlanVC {
                patientVC.username5 = username4
                self.navigationController?.pushViewController(patientVC, animated: true)
            } else {
                print("Error: Unable to instantiate PatientPlanVC")
            }
        }

        func patientScoreAPI() {
            let urlString = "\(ServiceAPI.baseURL)category.php"
            postPatientScores(urlString: urlString, username: ["name": username4]) { [weak self] result in
                switch result {
                case .success(let data):
                    DispatchQueue.main.async {
                        self?.patientScoreData = data
                        self?.progressBar()
                    }
                case .failure(let error):
                    print(error)
                }
            }
        }
    }

    extension PcosCategory {
        func postPatientScores(urlString: String, username: [String: String], completion: @escaping (Result<PaitentScoreModel, Error>) -> Void) {
            guard let url = URL(string: urlString) else {
                print("Invalid URL")
                return
            }

            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.addValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

            let parameters = username.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            request.httpBody = parameters.data(using: .utf8)

            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                guard let data = data, error == nil else {
                    completion(.failure(error ?? NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Unknown data error"])))
                    return
                }

                do {
                    let decodedData = try JSONDecoder().decode(PaitentScoreModel.self, from: data)
                    completion(.success(decodedData))
                } catch {
                    completion(.failure(error))
                }
            }

            task.resume()
        }
    }