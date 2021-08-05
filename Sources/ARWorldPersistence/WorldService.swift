//
//  WorldPersistenceService.swift
//  ARPersistence
//
//  Created by Lamar Woods on 8/5/21.
//  Copyright © 2021 Apple. All rights reserved.
//

import Foundation
import ARKit

public class WorldService {
    public init() {
        
    }
    
    lazy var mapSaveURL: URL = {
        do {
            return try FileManager.default
                .url(for: .documentDirectory,
                     in: .userDomainMask,
                     appropriateFor: nil,
                     create: true)
                .appendingPathComponent("map.arexperience")
        } catch {
            fatalError("Can't get file save URL: \(error.localizedDescription)")
        }
    }()
    
    // Called opportunistically to verify that map data can be loaded from filesystem.
    public var mapDataFromFile: Data? {
        return try? Data(contentsOf: mapSaveURL)
    }
    
    public func saveExperience(map: ARWorldMap, currentFrame: ARFrame?, didSaveSuccessfully: @escaping ()->Void) {
        // Add a snapshot image indicating where the map was captured.
        guard let frame = currentFrame, let snapshotAnchor = SnapshotAnchor(currentFrame: frame)
            else { fatalError("Can't take snapshot") }
        map.anchors.append(snapshotAnchor)
        
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
            try data.write(to: self.mapSaveURL, options: [.atomic])
            DispatchQueue.main.async {
                didSaveSuccessfully()
            }
        } catch {
            fatalError("Can't save map: \(error.localizedDescription)")
        }
    }
    
    public func loadExperience() -> (ARWorldMap, Data?) {
        /// - Tag: ReadWorldMap
        let worldMap: ARWorldMap = {
            guard let data = mapDataFromFile
                else { fatalError("Map data should already be verified to exist before Load button is enabled.") }
            do {
                guard let worldMap = try NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data)
                    else { fatalError("No ARWorldMap in archive.") }
                return worldMap
            } catch {
                fatalError("Can't unarchive ARWorldMap from file data: \(error)")
            }
        }()
        
        let snapshotData = worldMap.snapshotAnchor?.imageData
        // Remove the snapshot anchor from the world map since we do not need it in the scene.
        worldMap.anchors.removeAll(where: { $0 is SnapshotAnchor })
        
        return (worldMap, snapshotData)
    }
}
