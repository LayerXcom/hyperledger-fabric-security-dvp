package main

import (
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"unsafe"

	"github.com/hyperledger/fabric/core/chaincode/shim"
	sc "github.com/hyperledger/fabric/protos/peer"
)

// SecurityManagerChaincode 証券に関する関数を提供
type SecurityManagerChaincode struct{}

// SecurityStatus 証券の状態を表す
type SecurityStatus int

const (
	Undefined SecurityStatus = iota
	Finalized
	Issued
)

const SECURITY_PURCHASE_REGISTRATION_KEY = "securityPurchaseRegistration"
const SECURITY_BALANCE_KEY = "securityBalance"
const SECURITY_KEY = "security"
const PLATFORM_MSPID = "platform"

// Security 証券に関する情報を格納
type Security struct {
	Name   string         `json:"name"`         //名前
	Issuer string         `json:"issuer"`       //発行体
	Units  uint64         `json:"units,string"` //発行口数
	Price  uint64         `json:"price,string"` //総発行額
	Status SecurityStatus //証券のステータス
}

// RequestSecurity 証券登録時に使用する証券の情報を格納
type RequestSecurity struct {
	UUID         string   `json:"uuid"`         //uuid
	SecurityInfo Security `json:"securityInfo"` //証券情報
}

// MintSecurity 証券発行時に誰にいくら発行するかの情報を格納
type MintSecurity struct {
	SecurityID   string `json:"securityId"`    //証券ID
	Amount       uint64 `json:"amount,string"` //発行額
	Organization string `json:"organization"`  //組織
	Identity     string `json:"identity"`      //アイデンティティ
}

// RequestPurchaseReservation ...
type RequestPurchaseReservation struct {
	SecurityID   string `json:"securityId"` //証券ID
	Organization string `json:"organization"`
	InvestorID   string `json:"investorId"` //投資家ID
	Units        uint64 `json:"units,string"`
}

// RequestIssueSecurity ...
type RequestIssueSecurity struct {
	SecurityID           string `json:"securityId"` // 証券ID
	TargetOrganization   string `json:"targetOrganization"`
	ReceiverOrganization string `json:"receiverOrganization"` // マネーの受け手の組織
	ReceiverIdentity     string `json:"receiverIdentity"`     // マネーの受け手のアイデンティ
}

// PurchaseInfo 証券購入登録情報
type PurchaseInfo struct {
	Units         uint64 //移転額
	IsTransferred bool   //移転完了の有無
}

// RequestTransferSecurity 証券の移転時に利用する情報を格納
type RequestTransferSecurity struct {
	SecurityID           string `json:"securityId"`           //証券ID
	Amount               uint64 `json:"amount,string"`        //移転額
	SenderOrganization   string `json:"senderOrganization"`   //送り手の組織
	SenderIdentity       string `json:"senderIdentity"`       //送り手のアイデンティティ
	ReceiverOrganization string `json:"receiverOrganization"` //受け手の組織
	ReceiverIdentity     string `json:"receiverIdentity"`     //受け手のアイデンティ
}

// RequestUpdateMoney ...
type RequestUpdateMoney struct {
	Amount       uint64 `json:"amount,string"`        //移転額
	Organization string `json:"receiverOrganization"` //受け手の組織
	Identity     string `json:"receiverIdentity"`     //受け手のアイデンティティ
	IsSender     bool
}

// GetSecurityBalance ...
type GetSecurityBalance struct {
	SecurityID   string `json:"securityId"`   //証券ID
	Organization string `json:"organization"` //組織
	Identity     string `json:"identity"`     //アイデンティティ
}

const NUMBER_OF_ARGUMENTS = 1

// Init ...
func (sm *SecurityManagerChaincode) Init(apiStub shim.ChaincodeStubInterface) sc.Response {
	return shim.Success(nil)
}

// Invoke ...
func (sm *SecurityManagerChaincode) Invoke(apiStub shim.ChaincodeStubInterface) sc.Response {
	// Retrieve the requested Smart Contract function and arguments
	function, args := apiStub.GetFunctionAndParameters()
	// Route to the appropriate handler function to interact with the ledger appropriately
	switch function {
	case "getSecurity":
		return sm.getSecurity(apiStub, args)
	case "createSecurity":
		return sm.createSecurity(apiStub, args)
	case "issueSecurity":
		return sm.issueSecurity(apiStub, args)
	case "queryAllSecurities":
		return sm.queryAllSecurities(apiStub)
	case "reservePurchase":
		return sm.reservePurchase(apiStub, args)
	case "finalizeSecurity":
		return sm.finalizeSecurity(apiStub, args)
	case "transferSecurity":
		return sm.transferSecurity(apiStub, args)
	case "getBalance":
		return sm.getBalance(apiStub, args)
	default:
		return shim.Error("Invalid Chaincode function name.")
	}
}

// どんな証券を発行するか
// 引数: {"uuid":\"security1\",\"securityInfo\":{\"name\":\"OneMilionSecurity\",\"issuer\":\"layerx\",\"units\":\"100\",\"size\":\"10000\"}
// DBでは key:security-{証券ID} value: Security
func (sm *SecurityManagerChaincode) createSecurity(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var securityRequest RequestSecurity
	var securityReqBody string = args[0]
	err := json.Unmarshal([]byte(securityReqBody), &securityRequest)
	if err != nil {
		return shim.Error("Failed unmarshal securityRequest: " + err.Error())
	}

	var securityUUID string = generateSecurityKey(SECURITY_KEY, securityRequest.UUID)
	var security Security = securityRequest.SecurityInfo
	securityAsBytes, err := json.Marshal(security)
	if err != nil {
		return shim.Error("Failed marshal security: " + err.Error())
	}

	if _, err := json.Marshal(securityUUID); err != nil {
		return shim.Error("Failed marshal securityUUID: " + err.Error())
	}

	apiStub.PutState(securityUUID, securityAsBytes)
	if err != nil {
		return shim.Error("Failed putState securityAsBytes: " + err.Error())
	}

	return shim.Success(securityAsBytes)
}

// どの証券を発行するか
// 引数: {\"security\":\"security1\"}
func (sm *SecurityManagerChaincode) finalizeSecurity(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var securityKey string = generateSecurityKey(SECURITY_KEY, args[0])
	var security Security
	securityAsBytes, _ := apiStub.GetState(securityKey)
	err := json.Unmarshal(securityAsBytes, &security)
	if err != nil {
		return shim.Error("Failed unmarshal securityAsBytes: " + err.Error())
	}

	security.Status = Finalized
	securityAsBytes, err = json.Marshal(security)
	if err != nil {
		return shim.Error("Failed marshal security: " + err.Error())
	}

	if err := apiStub.PutState(securityKey, securityAsBytes); err != nil {
		return shim.Error("Failed putState securityAsBytes: " + err.Error())
	}

	return shim.Success(securityAsBytes)
}

// issueSecurity ...
func (sm *SecurityManagerChaincode) issueSecurity(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	// 実行者がplatformかどうかを確認
	ok, err := sm.isPlatform(apiStub)
	if err != nil {
		return shim.Error("Failed isPlatform" + err.Error())
	}

	if !ok {
		return shim.Error("Executor is not platform")
	}

	issueSecurityRequest := RequestIssueSecurity{}
	invokeArgs := args[0]
	if err := json.Unmarshal([]byte(invokeArgs), &issueSecurityRequest); err != nil {
		return shim.Error("Failed unmarshal: " + err.Error())
	}

	securityID := generateSecurityKey(SECURITY_KEY, issueSecurityRequest.SecurityID)
	// 指定した証券が存在するかどうかを確認
	securityAsBytes, err := apiStub.GetState(securityID)
	if err != nil {
		return shim.Error("Failed getState security: " + err.Error())
	}

	if securityAsBytes == nil {
		return shim.Error("Not found security")
	}

	// 取得したJSONを構造体に変換
	security := Security{}
	if err := json.Unmarshal(securityAsBytes, &security); err != nil {
		return shim.Error("Failed security unmarshal: " + err.Error())
	}

	// 証券がされているかを確認
	if security.Status != Finalized {
		return shim.Error("Security has not been finalized.")
	}

	startKey := generateSecurityKey(SECURITY_PURCHASE_REGISTRATION_KEY, securityID, issueSecurityRequest.TargetOrganization, "investor0")
	// 999までの制限をなくす
	endKey := generateSecurityKey(SECURITY_PURCHASE_REGISTRATION_KEY, securityID, issueSecurityRequest.TargetOrganization, "investor999")
	resultsIterator, err := apiStub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}

	defer resultsIterator.Close()

	var receiverTotalAmount uint64 = 0
	// loop開始
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}

		kSlice := strings.Split(queryResponse.Key, "-")
		investorOrganization := kSlice[3]
		investorIdentity := kSlice[4]

		// 投資家の証券購入情報をJSONから構造体に変換
		purchaseReservation := &PurchaseInfo{}
		if err := json.Unmarshal(queryResponse.Value, &purchaseReservation); err != nil {
			return shim.Error("Failed purchaseReservation unmarshal: " + err.Error())
		}

		// 証券購入済の場合はcontinue
		if purchaseReservation.IsTransferred {
			continue
		}

		// 投資家のMoney残高更新
		amount := purchaseReservation.Units * security.Price
		r := RequestUpdateMoney{
			Amount:       amount,
			Identity:     investorIdentity,
			Organization: investorOrganization,
			IsSender:     true,
		}
		if _, err := sm.callUpdateMoney(apiStub, r); err != nil {
			return shim.Error("Failed callUpdateMoney: " + err.Error())
		}

		// loop処理が終わったら発行体の残高を更新する
		receiverTotalAmount += amount

		// mintSecurity
		mintSecurity := MintSecurity{
			SecurityID:   securityID,// issueSecurityRequest.SecurityID,
			Amount:       purchaseReservation.Units,
			Organization: investorOrganization,
			Identity:     investorIdentity,
		}
		mintSecurityJSON, err := json.Marshal(mintSecurity)
		if err != nil {
			return shim.Error("Failed mintSecurity json marshal" + err.Error())
		}

		mintSecurityArg := []string{string(mintSecurityJSON)}
		// mintSecurityの結果は不要
		if _, err := sm.mintSecurity(apiStub, mintSecurityArg); err != nil {
			return shim.Error("Failed mintSecurity: " + err.Error())
		}

		// 購入済にステータスを変更
		purchaseReservation.IsTransferred = true

		// 証券購入情報を更新
		investorAtBytes, err := json.Marshal(purchaseReservation)
		if err != nil {
			return shim.Error("Failed purchaseReservation json.Marshal: " + err.Error())
		}

		apiStub.PutState(queryResponse.Key, investorAtBytes)
	}

	// 発行体の口座を更新
	r := RequestUpdateMoney{
		Amount:       receiverTotalAmount,
		Identity:     issueSecurityRequest.ReceiverIdentity,
		Organization: issueSecurityRequest.ReceiverOrganization,
		IsSender:     false, // 受け手は発行体なのでfalse
	}
	if _, err := sm.callUpdateMoney(apiStub, r); err != nil {
		return shim.Error("Failed callUpdateMoney: " + err.Error())
	}

	return shim.Success(nil)
}

// どの証券を誰にいくらmintするか
// 引数: {\"amount\":\"100\",\"organization\":\"MinatoBank\",\"identity\":\"investor01\"}
// DBでは key:securityBalance-security-{証券ID}-{組織ID}-{投資家ID}, value:残高
// 例） key:securityBalance-security-security1-MinatoBank-investor01 value:200
func (sm *SecurityManagerChaincode) mintSecurity(apiStub shim.ChaincodeStubInterface, args []string) ([]byte, error) {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return nil, errors.New("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var mintSecurity MintSecurity
	var identity string = args[0]
	err := json.Unmarshal([]byte(identity), &mintSecurity)
	if err != nil {
		return nil, errors.New("Failed unmarshal identity: " + err.Error())
	}

	balanceAsBytes := []byte(strconv.FormatUint(mintSecurity.Amount, 10))
	var key string = generateSecurityKey(SECURITY_BALANCE_KEY, mintSecurity.SecurityID, mintSecurity.Organization, mintSecurity.Identity)
	var collectionName string = fmt.Sprintf("%sSecurityBalance", mintSecurity.Organization)
	err = apiStub.PutPrivateData(collectionName, key, balanceAsBytes)
	if err != nil {
		return nil, errors.New("Failed PutPrivateData balance: " + err.Error())
	}

	return balanceAsBytes, nil
}

// 誰から誰にいくらmintする
// 引数: {"amount":"100","senderOrganization":"MinatoBank","senderIdentity":"investor01","receiverOrganization":"MinatoBank","receiverIdentity":"investor01"}
func (sm *SecurityManagerChaincode) transferSecurity(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var transferSecurity RequestTransferSecurity
	var transferInfo string = args[0]
	err := json.Unmarshal([]byte(transferInfo), &transferSecurity)
	if err != nil {
		return shim.Error("Failed unmarshal transferInfo: " + err.Error())
	}

	// senderの残高を減らす
	//// Securityの情報取得
	var senderBalance uint64
	var senderBalanceKey string = generateSecurityKey(SECURITY_BALANCE_KEY, transferSecurity.SecurityID, transferSecurity.SenderOrganization, transferSecurity.SenderIdentity)
	var senderCollectionName string = fmt.Sprintf("%sSecurityBalance", transferSecurity.SenderOrganization)
	senderSecurityBalanceAsBytes, err := apiStub.GetPrivateData(senderCollectionName, senderBalanceKey)
	if err != nil {
		return shim.Error("Failed GetPrivateData senderSecurityBalance: " + err.Error())
	}
	err = json.Unmarshal(senderSecurityBalanceAsBytes, &senderBalance)
	if err != nil {
		return shim.Error("Failed unmarshal senderSecurityBalanceAsBytes: " + err.Error())
	}
	//// senderの残高が足りているかバリデーション
	if senderBalance < transferSecurity.Amount {
		return shim.Error("Unsufficient amount of balance")
	}
	senderBalance -= transferSecurity.Amount
	senderSecurityBalanceAsBytes = []byte(strconv.FormatUint(senderBalance, 10))
	err = apiStub.PutPrivateData(senderCollectionName, senderBalanceKey, senderSecurityBalanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData senderSecurityBalance: " + err.Error())
	}

	// receiverの残高を増やす
	var receiverBalance uint64
	var receiverBalanceKey string = generateSecurityKey(SECURITY_BALANCE_KEY, transferSecurity.SecurityID, transferSecurity.ReceiverOrganization, transferSecurity.ReceiverIdentity)
	var receiverCollectionName string = fmt.Sprintf("%sSecurityBalance", transferSecurity.ReceiverOrganization)
	receiverSecurityBalanceAsBytes, err := apiStub.GetPrivateData(receiverCollectionName, receiverBalanceKey)
	if err != nil {
		return shim.Error("Failed GetPrivateData receiverSecurityBalance: " + err.Error())
	}

	if len(receiverSecurityBalanceAsBytes) == 0 {
		k := generateSecurityKey(SECURITY_BALANCE_KEY, transferSecurity.SecurityID, transferSecurity.ReceiverOrganization, transferSecurity.ReceiverIdentity)
		err = apiStub.PutPrivateData(receiverCollectionName, k, []byte("0"))
		if err != nil {
			return shim.Error("Failed PutPrivateData balance: " + err.Error())
		}
		receiverSecurityBalanceAsBytes = []byte("0")
	}

	err = json.Unmarshal(receiverSecurityBalanceAsBytes, &receiverBalance)
	if err != nil {
		return shim.Error("Failed unmarshal receiverSecurityBalanceAsBytes: " + err.Error())
	}
	receiverBalance += transferSecurity.Amount
	receiverSecurityBalanceAsBytes = []byte(strconv.FormatUint(receiverBalance, 10))
	apiStub.PutPrivateData(receiverCollectionName, receiverBalanceKey, receiverSecurityBalanceAsBytes)
	if err != nil {
		return shim.Error("Failed PutPrivateData receiverSecurityBalance: " + err.Error())
	}

	return shim.Success(receiverSecurityBalanceAsBytes)
}

func (sm *SecurityManagerChaincode) getBalance(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var getSecurityBalance GetSecurityBalance
	var queryInfo string = args[0]
	err := json.Unmarshal([]byte(queryInfo), &getSecurityBalance)
	if err != nil {
		return shim.Error("Failed unmarshal queryInfo: " + err.Error())
	}

	// Securityの情報取得
	var key string = generateSecurityKey(SECURITY_BALANCE_KEY, SECURITY_KEY, getSecurityBalance.SecurityID, getSecurityBalance.Organization, getSecurityBalance.Identity)
	var collectionName string = fmt.Sprintf("%sSecurityBalance", getSecurityBalance.Organization)
	securityBalanceAsBytes, err := apiStub.GetPrivateData(collectionName, key)
	if err != nil {
		return shim.Error("Failed GetPrivateData securityBalance: " + err.Error())
	}

	return shim.Success(securityBalanceAsBytes)
}

func (sm *SecurityManagerChaincode) getSecurity(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != 1 {
		return shim.Error("Incorrect number of arguments. Expecting 1")
	}

	var securityKey string = args[0]
	// Securityの情報取得だけに絞りたい
	securityAsBytes, err := apiStub.GetState(securityKey)
	if err != nil {
		return shim.Error("Failed getState security: " + err.Error())
	}
	return shim.Success(securityAsBytes)
}

// 証券の一覧取得
// 引数: なし
func (sm *SecurityManagerChaincode) queryAllSecurities(apiStub shim.ChaincodeStubInterface) sc.Response {
	startKey := "security-security0"
	// 999までの制限をなくす
	endKey := "security-security999"

	resultsIterator, err := apiStub.GetStateByRange(startKey, endKey)
	if err != nil {
		return shim.Error(err.Error())
	}
	defer resultsIterator.Close()

	// buffer is a JSON array containing QueryResults
	var buffer bytes.Buffer
	buffer.WriteString("[")

	bArrayMemberAlreadyWritten := false
	for resultsIterator.HasNext() {
		queryResponse, err := resultsIterator.Next()
		if err != nil {
			return shim.Error(err.Error())
		}
		// Add a comma before array members, suppress it for the first array member
		if bArrayMemberAlreadyWritten == true {
			buffer.WriteString(",")
		}
		buffer.WriteString("{\"Key\":")
		buffer.WriteString("\"")
		buffer.WriteString(queryResponse.Key)
		buffer.WriteString("\"")

		buffer.WriteString(", \"Record\":")
		// Record is a JSON object, so we write as-is
		buffer.WriteString(string(queryResponse.Value))
		buffer.WriteString("}")
		bArrayMemberAlreadyWritten = true
	}
	buffer.WriteString("]")

	fmt.Printf("- queryAllSecurities:\n%s\n", buffer.String())

	return shim.Success(buffer.Bytes())
}

// reservePurchase
// 証券購入量登録
// 引数: {"securityId":"security1","investorId":"investor01","units":"100"}
func (sm *SecurityManagerChaincode) reservePurchase(apiStub shim.ChaincodeStubInterface, args []string) sc.Response {
	if len(args) != NUMBER_OF_ARGUMENTS {
		return shim.Error("Incorrect number of arguments. Expecting " + strconv.Itoa(NUMBER_OF_ARGUMENTS))
	}

	var req RequestPurchaseReservation
	if err := json.Unmarshal([]byte(args[0]), &req); err != nil {
		return shim.Error("Failed reservePurchase unmarshal: " + err.Error())
	}

	purchaseInfo := PurchaseInfo{}
	purchaseInfo.Units = req.Units
	purchaseInfoAtBytes, err := json.Marshal(purchaseInfo)
	if err != nil {
		return shim.Error("Failed purchaseInfo json.Marshal" + err.Error())
	}

	var key string = generateSecurityKey(SECURITY_PURCHASE_REGISTRATION_KEY, SECURITY_KEY, req.SecurityID, req.Organization, req.InvestorID)
	// 登録
	apiStub.PutState(key, purchaseInfoAtBytes)

	return shim.Success(purchaseInfoAtBytes)
}

func (sm *SecurityManagerChaincode) isPlatform(apiStub shim.ChaincodeStubInterface) (bool, error) {
	creator, err := apiStub.GetCreator()
	if err != nil {
		return false, errors.New("Failed GetCreator" + err.Error())
	}
	fmt.Println("### c: ", *(*string)(unsafe.Pointer(&creator)))

	/*
		issueSecurityを実行し、GetCreator()で確認すると下記のデータが取れる
		証明書の先頭のところにplatformという文字列が入っている

		platform-----BEGIN CERTIFICATE-----
		MIICsjCCAligAwIBAgIUDzzQ9EC8Dfe5fmIwTK1QeHfgsIIwCgYIKoZIzj0EAwIw
		aDELMAkGA1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5hMRQwEgYDVQQK
		EwtIeXBlcmxlZGdlcjEPMA0GA1UECxMGRmFicmljMRkwFwYDVQQDExBmYWJyaWMt
		Y2Etc2VydmVyMB4XDTIwMDMzMTExNDUwMFoXDTIxMDMzMTExNTAwMFowaDELMAkG
		A1UEBhMCVVMxFzAVBgNVBAgTDk5vcnRoIENhcm9saW5hMRQwEgYDVQQKEwtIeXBl
		cmxlZGdlcjEPMA0GA1UECxMGY2xpZW50MRkwFwYDVQQDDBBiYW5rX3BlZXJfYWRt
		aW4xMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE3Z3+yp8QXjZOfzx+1W0G4qBb
		5a5g3/XyKQacZKWedYmoA7jpxfSxT6E0U6F435a5QzB+JHzG59K2jtrnv58M0KOB
		3zCB3DAOBgNVHQ8BAf8EBAMCB4AwDAYDVR0TAQH/BAIwADAdBgNVHQ4EFgQUYobB
		YQQt+YV1hlJ/TxlRFW4K1MAwHwYDVR0jBBgwFoAU4s0bV8ZTZIca746qYIIMi2ci
		NG0wFwYDVR0RBBAwDoIMNmEyNDMzZTNiNDAxMGMGCCoDBAUGBwgBBFd7ImF0dHJz
		Ijp7ImhmLkFmZmlsaWF0aW9uIjoiIiwiaGYuRW5yb2xsbWVudElEIjoiYmFua19w
		ZWVyX2FkbWluMSIsImhmLlR5cGUiOiJjbGllbnQifX0wCgYIKoZIzj0EAwIDSAAw
		RQIhAP2rys2jKkT072CNkn2LDP/iCkegtM3BwKGKkg1rgSTRAiAvucsNE97RRm+O
		7ItIiNyfi1i/QF6ajp4ktGVQ3lRkYg==
		-----END CERTIFICATE-----
	*/
	//
	if !strings.Contains(*(*string)(unsafe.Pointer(&creator)), PLATFORM_MSPID) {
		return false, nil
	}

	return true, nil
}

func (sm *SecurityManagerChaincode) callUpdateMoney(apiStub shim.ChaincodeStubInterface, req RequestUpdateMoney) ([]byte, error) {
	updateMoneyJSON, err := json.Marshal(req)
	if err != nil {
		return nil, errors.New("Failed callUpdateMoney json marshal")
	}

	chaincodeName := "money"
	channelName := "all-ch"
	funcName := "updateMoney"
	invokeArgs := toChaincodeArgs(funcName, string(updateMoneyJSON))
	response := apiStub.InvokeChaincode(chaincodeName, invokeArgs, channelName)
	if response.Status != shim.OK {
		errStr := fmt.Sprintf("Failed to invoke chaincode. Got error: %s", string(response.Payload))
		fmt.Printf(errStr)

		return nil, errors.New(errStr)
	}

	return response.Payload, nil
}

func toChaincodeArgs(args ...string) [][]byte {
	bargs := make([][]byte, len(args))
	for i, arg := range args {
		bargs[i] = []byte(arg)
	}
	return bargs
}

func generateSecurityKey(args ...string) string {
	key := strings.Join(args, "-")

	return key
}

func main() {
	// Create a new Smart Contract
	err := shim.Start(new(SecurityManagerChaincode))
	if err != nil {
		fmt.Printf("Error creating new Chaincode: %s", err)
	}
}
