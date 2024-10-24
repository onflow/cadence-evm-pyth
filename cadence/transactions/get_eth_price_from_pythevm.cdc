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
        balance.setFLOW(flow: UFix64(10))


        let callResult = self.coa.call(
            to: self.evmAddress,
            data: EVM.encodeABIWithSignature("fetchPrice(string,string)", [pythHermesUpdateDataPayload, tokenPriceFeedId]),
            gasLimit: 15_000_000,
            value: balance
        )

        assert(
            callResult.status == EVM.Status.failed || callResult.status == EVM.Status.successful,
            message: "evm_error=".concat(callResult.errorMessage).concat("\n")
        )

        let decoded = EVM.decodeABI(types: [Type<String>()], data: callResult.data)
        assert(decoded.length == 1, message: "Expected decoded length of 1 but got ".concat(decoded.length.toString()))
        let strData = decoded[0] as! String

        log(strData)
    }
}