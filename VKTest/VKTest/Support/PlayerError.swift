//
//  PlayerError.swift
//  VKTest
//
//  Created by Артём Калинин on 06.02.2022.
//

import Foundation

enum PlayerError: Error {

    case notURLConvertible
    case wrongURL
    case emptyInput
    case unknown
    
    var description: String {
        switch self {
        case .notURLConvertible:
            return "Невозможно создать URL из введенной строки. Попробуйте еще раз."
        case .wrongURL:
            return "Кажется, вы ввели неправильный URL. Попробуйте еще раз."
        case .emptyInput:
            return "Вы не ввели URL. Попробуйте еще раз."
        case .unknown:
            return "Произошла неизвестная ошибка. Попробуйте еще раз."
        }
    }

}
