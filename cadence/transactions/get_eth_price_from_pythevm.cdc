import "EVM"

transaction(myPythCallingContractAddressHex: String, pythHermesUpdateDataPayload: String, tokenPriceFeedId: String) {

    let evmAddress: EVM.EVMAddress
    let coa: auth(EVM.Call) &EVM.CadenceOwnedAccount

    prepare(signer: auth(BorrowValue) &Account) {
        self.evmAddress = EVM.addressFromString(myPythCallingContractAddressHex)

        self.coa = signer.storage.borrow<auth(EVM.Call) &EVM.CadenceOwnedAccount>(from: /storage/evm)
            ?? panic("Could not borrow COA from provided gateway address")
    }

    execute {
        let balance = EVM.Balance(attoflow: 0)

        let callResult = self.coa.call(
            to: self.evmAddress,
            data: EVM.encodeABIWithSignature("fetchPrice(string,string)", [pythHermesUpdateDataPayload, tokenPriceFeedId]),
            gasLimit: 15_000_000,
            value: balance
        )

        assert(callResult.status == EVM.Status.successful, message: "Call failed")

        var res = EVM.decodeABI(types: [Type<UInt256>()], data: callResult.data)

        assert(res.length == 1, message: "Invalid response length")
        log(res[0] as! UInt256)
    }
}