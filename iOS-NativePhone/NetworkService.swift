//
//  NetworkService.swift
//  NotificationLiquidGlass
//
//  Created by Andres Marin on 13/02/26.
//

import Foundation

class NetworkService {
    static let shared = NetworkService()
    
    // URL completa que apunta directamente al JSON del chat
    // Puede ser cualquier URL que retorne un JSON válido
    var baseURL: String = "https://oktana156-dev-ed.develop.my.site.com/endpoint/resource/chatConfigs/chatConfigs.json"
    
    func fetchChatConfig(completion: @escaping (Result<AppConfig, Error>) -> Void) {
        // Si la URL está vacía o es solo espacios en blanco, usar JSON local
        let trimmedURL = baseURL.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedURL.isEmpty {
            print("URL vacía, cargando JSON local...")
            loadLocalChatConfig(completion: completion)
            return
        }
        
        // Usar directamente la URL tal como fue configurada
        guard let url = URL(string: baseURL) else {
            let error = NSError(
                domain: "NetworkService",
                code: 400,
                userInfo: [
                    NSLocalizedDescriptionKey: "URL inválida: \(baseURL)"
                ]
            )
            print("URL inválida: \(baseURL)")
            completion(.failure(error))
            return
        }
        
        print("Fetching chat config from: \(url.absoluteString)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Network error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            // Verificar el código de respuesta HTTP
            if let httpResponse = response as? HTTPURLResponse {
                print("HTTP Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode != 200 {
                    let statusError = NSError(
                        domain: "NetworkService",
                        code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey: "Error HTTP \(httpResponse.statusCode). Verifica que la URL sea correcta."
                        ]
                    )
                    completion(.failure(statusError))
                    return
                }
            }
            
            guard let data = data else {
                print("No data received")
                let noDataError = NSError(
                    domain: "NetworkService",
                    code: 404,
                    userInfo: [
                        NSLocalizedDescriptionKey: "No se recibieron datos del servidor. URL: \(url.absoluteString)"
                    ]
                )
                completion(.failure(noDataError))
                return
            }
            
            print("Data received: \(data.count) bytes")
            
            // Debug: Imprimir los primeros 500 caracteres del JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = String(jsonString.prefix(500))
                print("JSON Preview: \(preview)")
            }
            
            do {
                let decodedData = try JSONDecoder().decode(AppConfig.self, from: data)
                print("JSON decoded successfully")
                completion(.success(decodedData))
            } catch {
                print("JSON decode error: \(error)")
                
                // Crear error más descriptivo
                let decodeError = NSError(
                    domain: "NetworkService",
                    code: 500,
                    userInfo: [
                        NSLocalizedDescriptionKey: "Error al decodificar JSON: \(error.localizedDescription)"
                    ]
                )
                completion(.failure(decodeError))
            }
        }.resume()
    }
    
    // MARK: - Local JSON Loading
    
    /// Carga el JSON desde el bundle local cuando no hay URL configurada
    private func loadLocalChatConfig(completion: @escaping (Result<AppConfig, Error>) -> Void) {
        // Buscar el archivo JSON en el bundle principal
        guard let fileURL = Bundle.main.url(forResource: "Configs", withExtension: "json") else {
            let error = NSError(
                domain: "NetworkService",
                code: 404,
                userInfo: [
                    NSLocalizedDescriptionKey: "No se encontró el archivo JSON local 'Configs.json' en el bundle."
                ]
            )
            print("Archivo JSON local no encontrado")
            completion(.failure(error))
            return
        }
        
        print("Cargando JSON local desde: \(fileURL.lastPathComponent)")
        
        do {
            let data = try Data(contentsOf: fileURL)
            print("JSON local cargado: \(data.count) bytes")
            
            // Debug: Imprimir los primeros 500 caracteres del JSON
            if let jsonString = String(data: data, encoding: .utf8) {
                let preview = String(jsonString.prefix(500))
                print("JSON Preview: \(preview)")
            }
            
            let decodedData = try JSONDecoder().decode(AppConfig.self, from: data)
            print("JSON local decodificado exitosamente")
            completion(.success(decodedData))
            
        } catch {
            print("Error al cargar o decodificar JSON local: \(error)")
            let loadError = NSError(
                domain: "NetworkService",
                code: 500,
                userInfo: [
                    NSLocalizedDescriptionKey: "Error al cargar JSON local: \(error.localizedDescription)"
                ]
            )
            completion(.failure(loadError))
        }
    }
}
