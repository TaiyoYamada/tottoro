//
//  CredentialProviderViewController.swift
//  TottoroAutoFill
//
//  Created by 山田大陽 on 2026/10/18.
//

import AuthenticationServices
import SwiftUI

/// 自動入力の拡張の入口。OS から来る要求を OneTimeCodePickerViewModel に渡し、画面は SwiftUI で出す。
final class CredentialProviderViewController: ASCredentialProviderViewController {
    #if os(macOS)
    // NSViewController は nib がないと view を作れないので、自分で用意する
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 380, height: 480))
    }
    #endif

    /// QuickType バーなどで候補が選ばれたとき。コードを出す前に必ずロックを解除させたいので、画面付きの流れに回す。
    override func provideCredentialWithoutUserInteraction(for credentialRequest: any ASCredentialRequest) {
        extensionContext.cancelRequest(withError: ASExtensionError(.userInteractionRequired))
    }

    override func prepareInterfaceToProvideCredential(for credentialRequest: any ASCredentialRequest) {
        guard let recordIdentifier = credentialRequest.credentialIdentity.recordIdentifier,
              let accountID = UUID(uuidString: recordIdentifier)
        else {
            extensionContext.cancelRequest(withError: ASExtensionError(.credentialIdentityNotFound))
            return
        }
        show(mode: .provide(accountID))
    }

    /// 入力欄の「パスコード」ボタンから、すべてのコードの一覧を開いたとき。
    override func prepareOneTimeCodeCredentialList(for serviceIdentifiers: [ASCredentialServiceIdentifier]) {
        show(mode: .pick(serviceIdentifiers.map(\.identifier)))
    }

    private func show(mode: OneTimeCodePickerViewModel.Mode) {
        let viewModel = OneTimeCodePickerViewModel(mode: mode) { [extensionContext] result in
            switch result {
            case .code(let code):
                extensionContext.completeOneTimeCodeRequest(
                    using: ASOneTimeCodeCredential(code: code),
                    completionHandler: nil
                )
            case .canceled:
                extensionContext.cancelRequest(withError: ASExtensionError(.userCanceled))
            case .notFound:
                extensionContext.cancelRequest(withError: ASExtensionError(.credentialIdentityNotFound))
            case .failed(let error):
                extensionContext.cancelRequest(withError: error)
            }
        }
        #if os(iOS)
        let host = UIHostingController(rootView: OneTimeCodePickerView(viewModel: viewModel))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(host.view)
        host.didMove(toParent: self)
        #elseif os(macOS)
        let host = NSHostingController(rootView: OneTimeCodePickerView(viewModel: viewModel))
        addChild(host)
        host.view.frame = view.bounds
        host.view.autoresizingMask = [.width, .height]
        view.addSubview(host.view)
        #endif
    }
}
