//
//  DeveloperView.swift
//  Wallet
//
//  Created by Ronald Mannak on 10/14/21.
//

import SwiftUI
import MEWwalletKit
import SafariWalletCore
#if DEBUG
struct DeveloperView: View {
    
    let manager = WalletManager()
    @State var walletCount: Int = 0
    @State var errorMessage: String = ""
    @State var isOnBoardingPresented: Bool = false {
        didSet {
            self.countWallets()
        }
    }
    
    var body: some View {
        VStack {
            
            Text("Developer settings")
                .font(.title)
                .padding()
            
            if walletCount == 0 {
                Text("No wallets found")
            } else if walletCount == 1 {
                Text("1 wallet found")
            } else if walletCount < 1 {
                Text("Could not count wallets: \(errorMessage)")
            } else {
                Text("wallets found: \(walletCount)")
            }
            
            Spacer()
            
            Group {
                Text("Web3 test calls")
                    .font(.title3)
                    .padding()
                
                Button("sign message") {
                    Task {
                        try await manager.fetchAccount()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                
                Button("get balance") {
                    Task {
                        do {
                            let client = EthereumClient(provider: .alchemy(key: alchemyMainnetKey))!
                            let balance = try await client.ethGetBalance(address: "0xAb5801a7D398351b8bE11C439e05C5B3259aeC9B", blockNumber: .latest)
                            print(balance.description)
                            let height = try await client.ethBlockNumber()
                            print(height)
                        } catch {
                            print(error)
                        }
                    }
                }
                .buttonStyle(.bordered)
               
                Button("Call alchemy_getAssetTransfers") {
                  Task {
                     do {
                        let client = AlchemyClient(key: alchemyMainnetKey)!
                        //https://docs.alchemy.com/alchemy/documentation/enhanced-apis/transfers-api
                        let transfers = try await client.alchemyAssetTransfers(fromBlock: Block(rawValue: "A97AB8"),
                                                                               toBlock: Block(rawValue: "A97CAC"),
                                                                               fromAddress: Address(address: "3f5CE5FBFe3E9af3971dD833D26bA9b5C936f0bE"),
                                                                               contractAddresses: [
                                                                                  Address(address: "7fc66500c84a76ad7e9c93437bfc5ac33e2ddae9")!
                                                                               ],
                                                                               excludeZeroValue: true,
                                                                               maxCount: 5)
                        print(transfers)
                     } catch {
                        print(error)
                     }
                   }
                }
                .buttonStyle(.bordered)
            }
            
            Text("Wallet")
                .font(.title3)
                .padding()
            
            Button("Create a new wallet") {
                isOnBoardingPresented = true
            }
            .buttonStyle(.bordered)
            
            Text("Shows new wallet popup")
                .padding(.bottom)
            
            Button("Create a new test wallet") {
                Task {
                    do {
                        try await self.createTestWallet()
                    } catch {
                        print("Error creating test wallet: \(error.localizedDescription)")
                    }
                }
            }
            .padding(.top)
            
            Text("Instantly creates a new wallet with the default password 'password123' and makes it the default wallet. Takes up to 5 seconds in debug mode.")
                
            Button("Delete all wallets on disk", role: .destructive) {
                try? manager.deleteAllWallets()
                try? manager.deleteAllAddresses()
                countWallets()
            }
            .buttonStyle(.borderedProminent)
            .padding()
            
        }
        .padding()
        .onAppear {
            countWallets()
        }
        .sheet(isPresented: $isOnBoardingPresented) { OnboardingView(isCancelable: true) }
    }
}

extension DeveloperView {
    
    func countWallets() {
        do {
            walletCount = try manager.listWalletFiles().count
        } catch {
            walletCount = -1
            errorMessage = error.localizedDescription
        }
    }

    func createTestWallet() async throws {
        let root = try BIP39(bitsOfEntropy: 128)
        let mnemonic = root.mnemonic!.joined(separator: " ")
        let manager = WalletManager()
        let name = try await manager.saveWallet(mnemonic: mnemonic, password: "password123")
        let addresses = try await manager.saveAddresses(mnemonic: mnemonic, addressCount: 5, name: name)     
        try await manager.setDefaultWallet(to: name)
        countWallets()
    }
    
}

struct DeveloperView_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperView()
    }
}

#endif
