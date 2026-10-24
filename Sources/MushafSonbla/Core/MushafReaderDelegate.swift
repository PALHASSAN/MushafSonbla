//
//  MushafReaderDelegate.swift
//  MushafSonbla
//
//  Created by Alhassan AlMakki on 13/05/1448 AH.
//

import Foundation

@MainActor
public protocol MushafReaderDelegate: AnyObject {
    func mushafReader(_ reader: AnyObject, didScrollTo pageNumber: Int)
    func mushafReader(_ reader: AnyObject, didCompleteTargetSession session: MushafSession)
    func mushafReader(_ reader: AnyObject, didSelectAyah ayah: Ayah)
}

public extension MushafReaderDelegate {
    func mushafReader(_ reader: AnyObject, didScrollTo pageNumber: Int) {}
    func mushafReader(_ reader: AnyObject, didCompleteTargetSession session: MushafSession) {}
    func mushafReader(_ reader: AnyObject, didSelectAyah ayah: Ayah) {}
}
