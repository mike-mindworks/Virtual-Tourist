//
//  FlickrClient.swift
//  Virtual Tourist
//
//  Created by Mike Allan on 2020-10-22.
//

import Foundation

class FlickrClient {
    
    static let apiKey = "533335d4d6a4d8fd17dee41820e693a2"

    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/"
        static let photoBase = "https://live.staticflickr.com/"
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        static let formatParam = "&format=json&nojsoncallback=1"

        case getPhotos(String, String, Int)
        case getPhotoImage(String, String, String)
        
        var stringValue: String {
            switch self {
                case .getPhotos(let lat, let lon, let page): return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyParam + Endpoints.formatParam + "&lat=\(lat)&lon=\(lon)&page=\(page)"
            case .getPhotoImage(let serverId, let photoId, let photoSecret): return Endpoints.photoBase + "\(serverId)/\(photoId)_\(photoSecret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func getPhotos(lat: String, long: String, page: Int, completion: @escaping (Photos?, Error?) -> Void) {
        _ = taskForGETRequest(url: Endpoints.getPhotos(lat, long, page).url, responseType: GetPhotosResponse.self) { (getPhotosResponse, error) in
            print("Targeted: \(Endpoints.getPhotos(lat, long, page).stringValue)")
            if let error = error {
                print("Error caught in getNewPhotos(): \(error)")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            print("getNewPhotos() returned: \(getPhotosResponse!.photos.photo.count)")
            completion(getPhotosResponse!.photos, nil)
        }
    }
    
    class func downloadPhotoImage(serverId: String, photoId: String, photoSecret: String, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.getPhotoImage(serverId, photoId, photoSecret).url) { data, response, error in
            guard let data = data else {
                print("No data returned for image")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            DispatchQueue.main.async {
                completion(data, nil)
            }
        }
        task.resume()
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                print("GET request returned no data")
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            print("GET request returned \(String(data: data, encoding: .utf8)!)")
            print("Translating to response object")
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            }
            catch {
                print("Exception caught translating to response object \(error)")
                do {
                    print("Converting the original data to a FlickrError")
                    let errorResponse = try decoder.decode(FlickrError.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                }
                catch {
                    print("Exception caught translating to response data to a FlickrError \(error)")
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        task.resume()
        return task
    }
}
