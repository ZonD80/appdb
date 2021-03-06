//
//  API+Promotions.swift
//  appdb
//
//  Created by ned on 26/01/2017.
//  Copyright © 2017 ned. All rights reserved.
//

import Alamofire

extension API {

    static func getPromotions(success:@escaping (_ items: [Promotion]) -> Void, fail:@escaping (_ error: NSError) -> Void) {
        Alamofire.request(endpoint, parameters: ["action": Actions.promotions.rawValue, "lang": languageCode], headers: headers)
            .responseArray(keyPath: "data") { (response: DataResponse<[Promotion]>) in
                switch response.result {
                case .success(let promotions):
                    success(promotions)
                case .failure(let error):
                    fail(error as NSError)
                }
            }
    }
}
