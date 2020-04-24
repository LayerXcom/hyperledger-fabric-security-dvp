package main

import (
	"encoding/json"
	"fmt"
	"strconv"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// MoneyChaincode マネーに関する関数を提供
type MoneyChaincode struct{}

// MintMoney マネー発行時に利用する情報を格納
type MintMoney struct {
	Amount       uint64 `json:"amount,string"` //発行額
	Organization string `json:"organization"`  //組織
	Identity     string `json:"identity"`      //アイデンティティ
}

// TransferMoney マネーの移転時に利用する情報を格納
type TransferMoney struct {
	Amount               uint64 `json:"amount,string"`        //移転額
	SenderOrganization   string `json:"senderOrganization"`   //送り手の組織
	SenderIdentity       string `json:"senderIdentity"`       //送り手のアイデンティティ
	ReceiverOrganization string `json:"receiverOrganization"` //受け手の組織
	ReceiverIdentity     string `json:"receiverIdentity"`     //受け手のアイデンティティ
}

// UpdateMoney マネーの残高更新情報を格納
type UpdateMoney struct {
	Amount       uint64 `json:"amount,string"`        //移転額
	Organization string `json:"receiverOrganization"` //受け手の組織
	Identity     string `json:"receiverIdentity"`     //受け手のアイデンティティ
	IsSender     bool
}

// GetMoneyBalance マネーの残高取得時に利用する情報を格納
type GetMoneyBalance struct {
	Organization string `json:"organization"` //組織
	Identity     string `json:"identity"`     //アイデンティティ
}

const NUMBER_OF_ARGUMENTS = 1
const MONEY_BALANCE = "moneyBalance"

// Init ...
func (mc *MoneyChaincode) Init(apiStub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

// Invoke ...
func (mc *MoneyChaincode) Invoke(apiStub shim.ChaincodeStubInterface) sc.Response {

	// Retrieve the requested Smart Contract function and arguments
	function, args := apiStub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	switch function {
	case "getBalance":
		return mc.getBalance(apiStub, args)
	case "mintMoney":
		return mc.mintMoney(apiStub, args)
	case "transferMoney":
		return mc.transferMoney(apiStub, args)
	case "updateMoney":
		return mc.updateMoney(apiStub, args)
	default:
		return shim.Error("Invalid Chaincode function name.")
	}
}

// 誰にいくらmintする
// 引数: {"amount":"100","organization":"MinatoBank","identity":"investor01"}
// DBでは key:moneyBalance-{組織ID}-{投資家ID}, value:残高
// 例） key:moneyBalance-MinatoBank-investor01, value:200
func (mc *MoneyChaincode) mintMoney(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var mintMoney MintMoney
	var mintInfo string = args[0]
	err := json.Unmarshal([]byte(mintInfo), &mintMoney)
	if err != nil {
		return shim.Error("Failed unmarshal1: " + err.Error())
	}

	balanceAsBytes := []byte(strconv.FormatUint(mintMoney.Amount, 10))

	var key string = fmt.Sprintf("%s-%s-%s", MONEY_BALANCE, mintMoney.Organization, mintMoney.Identity)
	var collectionName string = fmt.Sprintf("%sMoneyBalance", mintMoney.Organization)
	err = apiStub.PutPrivateData(collectionName, key, balanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData balance: " + err.Error())
	}

	return shim.Success(balanceAsBytes)
}

// 誰から誰にいくらmintする
// 引数: {"amount":"100","senderOrganization":"MinatoBank","senderIdentity":"investor01","receiverOrganization":"MinatoBank","receiverIdentity":"investor01"}
func (mc *MoneyChaincode) transferMoney(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var transferMoney TransferMoney
	var transferInfo string = args[0]
	err := json.Unmarshal([]byte(transferInfo), &transferMoney)
	if err != nil {
		return shim.Error("Failed unmarshal transferInfo: " + err.Error())
	}

	// senderの残高を減らす
	// Moneyの情報取得
	var senderBalance uint64
	var senderBalanceKey string = fmt.Sprintf("%s-%s-%s", MONEY_BALANCE, transferMoney.SenderOrganization, transferMoney.SenderIdentity)
	var senderCollectionName string = fmt.Sprintf("%sMoneyBalance", transferMoney.SenderOrganization)
	senderMoneyBalanceAsBytes, err := apiStub.GetPrivateData(senderCollectionName, senderBalanceKey)
	if err != nil {
		return shim.Error("Failed GetPrivateData senderBalance: " + err.Error())
	}

	err = json.Unmarshal(senderMoneyBalanceAsBytes, &senderBalance)
	if err != nil {
		return shim.Error("Failed unmarshal senderMoneyBalance: " + err.Error())
	}

	// senderの残高が足りているかバリデーション
	if senderBalance < transferMoney.Amount {
		return shim.Error("Unsufficient amount of balance")
	}

	senderBalance -= transferMoney.Amount
	senderMoneyBalanceAsBytes = []byte(strconv.FormatUint(senderBalance, 10))
	err = apiStub.PutPrivateData(senderCollectionName, senderBalanceKey, senderMoneyBalanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData senderBalance: " + err.Error())
	}

	// receiverの残高を増やす
	var receiverBalance uint64
	var receiverBalanceKey string = fmt.Sprintf("%s-%s-%s", MONEY_BALANCE, transferMoney.ReceiverOrganization, transferMoney.ReceiverIdentity)
	var receiverCollectionName string = fmt.Sprintf("%sMoneyBalance", transferMoney.ReceiverOrganization)

	receiverMoneyBalanceAsBytes, err := apiStub.GetPrivateData(receiverCollectionName, receiverBalanceKey)
	if err != nil {
		return shim.Error("Failed GetPrivateData receiverBalance: " + err.Error())
	}

	err = json.Unmarshal(receiverMoneyBalanceAsBytes, &receiverBalance)
	if err != nil {
		return shim.Error("Failed unmarshal receiverMoneyBalance: " + err.Error())
	}

	receiverBalance += transferMoney.Amount
	receiverMoneyBalanceAsBytes = []byte(strconv.FormatUint(receiverBalance, 10))
	err = apiStub.PutPrivateData(receiverCollectionName, receiverBalanceKey, receiverMoneyBalanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData receiverBalance: " + err.Error())
	}

	return shim.Success(nil)
}

func (mc *MoneyChaincode) updateMoney(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var updateMoney UpdateMoney
	var updateInfo string = args[0]
	err := json.Unmarshal([]byte(updateInfo), &updateMoney)
	if err != nil {
		return shim.Error("Failed unmarshal updateInfo: " + err.Error())
	}

	// receiverの残高を増やす
	var updateBalance uint64
	var updateBalanceKey string = fmt.Sprintf("%s-%s-%s", MONEY_BALANCE, updateMoney.Organization, updateMoney.Identity)
	var updateCollectionName string = fmt.Sprintf("%sMoneyBalance", updateMoney.Organization)
	updateMoneyBalanceAsBytes, err := apiStub.GetPrivateData(updateCollectionName, updateBalanceKey)
	if err != nil {
		return shim.Error("Failed GetPrivateData updateBalance: " + err.Error())
	}

	err = json.Unmarshal(updateMoneyBalanceAsBytes, &updateBalance)
	if err != nil {
		return shim.Error("Failed unmarshal updateMoneyBalance: " + err.Error())
	}

	if updateMoney.IsSender {
		updateBalance -= updateMoney.Amount
	} else {
		updateBalance += updateMoney.Amount
	}

	updateMoneyBalanceAsBytes = []byte(strconv.FormatUint(updateBalance, 10))
	err = apiStub.PutPrivateData(updateCollectionName, updateBalanceKey, updateMoneyBalanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData updateBalance: " + err.Error())
	}

	return shim.Success(nil)
}

// 誰の残高を取得する
// 引数: {"organization":"MinatoBank","identity":"investor01"}
func (mc *MoneyChaincode) getBalance(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {

	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var getMoneyBalance GetMoneyBalance
	var queryInfo string = args[0]
	err := json.Unmarshal([]byte(queryInfo), &getMoneyBalance)
	if err != nil {
		return shim.Error("Failed unmarshal queryInfo: " + err.Error())
	}
	// Moneyの情報取得
	var key string = fmt.Sprintf("%s-%s-%s", MONEY_BALANCE, getMoneyBalance.Organization, getMoneyBalance.Identity)
	var collectionName string = fmt.Sprintf("%sMoneyBalance", getMoneyBalance.Organization)
	moneyBalanceAsBytes, _ := apiStub.GetPrivateData(collectionName, key)
	if err != nil {
		return shim.Error("Failed GetPrivateData moneyBalance: " + err.Error())
	}
	return shim.Success(moneyBalanceAsBytes)
}

func main() {
	// Create a new Smart Chaincode
	err := shim.Start(new(MoneyChaincode))
	if err != nil {
		fmt.Printf("Error creating new Chaincode: %s", err)
	}
}
