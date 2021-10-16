// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.6;

import "./interface/INestPriceFacade.sol";
import "./interface/INestQuery.sol";
import "./interface/INestLedger.sol";
import "./interface/INestGovernance.sol";
import "./interface/INTokenController.sol";
import "./NestBase.sol";

/// @dev Price call entry
contract NestPriceFacade is NestBase, INestPriceFacade, INestQuery {

    // constructor() { }

    /// @dev Charge fee channel
    struct FeeChannel {

        // ntokenAddress of charge fee channel
        address ntokenAddress;

        // total fee to be settled of charge fee channel
        uint96 fee;
    }

    Config _config;
    address _nestLedgerAddress;
    address _nestQueryAddress;
    address _nTokenControllerAddress;

    /// @dev Unit of post fee. 0.0001 ether
    uint constant DIMI_ETHER = 0.0001 ether; // 1 ether / 10000;

    /// @dev Address flag. Only the address of the user whose address tag is consistent with the configuration tag 
    /// can call the price tag. (address=>flag)
    mapping(address=>uint) _addressFlags;

    /// @dev The nestQuery address mapped by this address is preferred for price query, which can be used to separate 
    /// nest price query and token price query. (tokenAddress=>INestQuery)
    mapping(address=>address) _nestQueryMapping;

    /// @dev Mapping from token address to charge fee channel. tokenAddress=>FeeChannel
    mapping(address=>FeeChannel) _channels;

    /// @dev Rewritten in the implementation contract, for load other contract addresses. Call 
    ///      super.update(nestGovernanceAddress) when overriding, and override method without onlyGovernance
    /// @param nestGovernanceAddress INestGovernance implementation contract address
    function update(address nestGovernanceAddress) public override {

        super.update(nestGovernanceAddress);
        (
            //address nestTokenAddress
            , 
            //address nestNodeAddress
            ,
            //address nestLedgerAddress
            _nestLedgerAddress, 
            //address nestMiningAddress
            ,
            //address ntokenMiningAddress
            ,
            //address nestPriceFacadeAddress
            , 
            //address nestVoteAddress
            , 
            //address nestQueryAddress
            _nestQueryAddress, 
            //address nnIncomeAddress
            , 
            //address nTokenControllerAddress
            _nTokenControllerAddress

        ) = INestGovernance(nestGovernanceAddress).getBuiltinAddress();
    }

    /// @dev Modify configuration
    /// @param config Configuration object
    function setConfig(Config calldata config) external override onlyGovernance {
        _config = config;
    }

    /// @dev Get configuration
    /// @return Configuration object
    function getConfig() external view override returns (Config memory) {
        return _config;
    }

    /// @dev Set the address flag. Only the address flag equals to config.normalFlag can the price be called
    /// @param addr Destination address
    /// @param flag Address flag
    function setAddressFlag(address addr, uint flag) external override onlyGovernance {
        _addressFlags[addr] = flag;
    }

    /// @dev Get the flag. Only the address flag equals to config.normalFlag can the price be called
    /// @param addr Destination address
    /// @return Address flag
    function getAddressFlag(address addr) external view override returns(uint) {
        return _addressFlags[addr];
    }

    /// @dev Set INestQuery implementation contract address for token
    /// @param tokenAddress Destination token address
    /// @param nestQueryAddress INestQuery implementation contract address, 0 means delete
    function setNestQuery(address tokenAddress, address nestQueryAddress) external override onlyGovernance {
        _nestQueryMapping[tokenAddress] = nestQueryAddress;
    }

    /// @dev Get INestQuery implementation contract address for token
    /// @param tokenAddress Destination token address
    /// @return INestQuery implementation contract address, 0 means use default
    function getNestQuery(address tokenAddress) external view override returns (address) {
        return _nestQueryMapping[tokenAddress];
    }

    // Get INestQuery implementation contract address for token
    function _getNestQuery(address tokenAddress) private view returns (address) {
        address addr = _nestQueryMapping[tokenAddress];
        if (addr == address(0)) {
            return _nestQueryAddress;
        }
        return addr;
    }

    /// @dev Set the ntokenAddress from tokenAddress
    /// @param tokenAddress Destination token address
    /// @param ntokenAddress The ntoken address
    function setNTokenAddress(address tokenAddress, address ntokenAddress) external onlyGovernance {
        _channels[tokenAddress].ntokenAddress = ntokenAddress;
    }

    /// @dev Get the ntokenAddress from tokenAddress
    /// @param tokenAddress Destination token address
    /// @return The ntoken address
    function getNTokenAddress(address tokenAddress) external view returns (address) {
        return _channels[tokenAddress].ntokenAddress;
    }

    /// @dev Get cached fee in fee channel
    /// @param tokenAddress Destination token address
    /// @return Cached fee in fee channel
    function getTokenFee(address tokenAddress) external view override returns (uint) {
        return uint(_channels[tokenAddress].fee);
    }

    // // Get ntoken address of from token address
    // function _getNTokenAddress(address tokenAddress) private returns (address) {
        
    //     address ntokenAddress = _addressCache[tokenAddress];
    //     if (ntokenAddress == address(0)) {
    //         ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
    //         if (ntokenAddress != address(0)) {
    //             _addressCache[tokenAddress] = ntokenAddress;
    //         }
    //     }
    //     return ntokenAddress;
    // }

    // Payment of transfer fee
    function _pay(address tokenAddress, uint fee, address paybackAddress) private {

        fee = fee * DIMI_ETHER;
        if (msg.value > fee) {
            payable(paybackAddress).transfer(msg.value - fee);
        } else {
            require(msg.value == fee, "NestPriceFacade:!fee");
        }

        // Load fee channel
        FeeChannel memory feeChannel = _channels[tokenAddress];
        // If ntokenAddress is cached, use it, else load it from INTokenController
        if (feeChannel.ntokenAddress == address(0)) {
            feeChannel.ntokenAddress = INTokenController(_nTokenControllerAddress).getNTokenAddress(tokenAddress);
        }

        // Check totalFee
        uint totalFee = fee + uint(feeChannel.fee);
        // totalFee less than 1 ether, add to fee
        if (totalFee < 1 ether)
        {
            feeChannel.fee = uint96(totalFee);
        }
        // totalFee reach 1 ether, collect
        else {
            feeChannel.fee = uint96(0);
            INestLedger(_nestLedgerAddress).addETHReward { 
                value: totalFee 
            } (feeChannel.ntokenAddress);
        }
        _channels[tokenAddress] = feeChannel;
    }

    /// @dev Settle fee for charge fee channel
    /// @param tokenAddress tokenAddress of charge fee channel
    function settle(address tokenAddress) external override {
        FeeChannel memory feeChannel = _channels[tokenAddress];
        if (uint(feeChannel.fee) > 0) {
            INestLedger(_nestLedgerAddress).addETHReward {
                value: uint(feeChannel.fee)
            } (feeChannel.ntokenAddress);
            feeChannel.fee = uint96(0);
            _channels[tokenAddress] = feeChannel;
        }
    }

    /* ========== INestPriceFacade ========== */

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress, 
        address paybackAddress
    ) external payable override returns (uint blockNumber, uint price) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice(tokenAddress);
    }

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(
        address tokenAddress, 
        address paybackAddress
    ) external payable override returns (
        uint blockNumber, 
        uint price, uint 
        avgPrice, 
        uint sigmaSQ
    ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo(tokenAddress);
    }

    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(
        address tokenAddress, 
        uint height, 
        address paybackAddress
    ) external payable override returns (uint blockNumber, uint price) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).findPrice(tokenAddress, height);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(
        address tokenAddress, 
        address paybackAddress
    ) external payable override returns (uint blockNumber, uint price) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice(tokenAddress);
    }

    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(
        address tokenAddress, 
        uint count, 
        address paybackAddress
    ) external payable override returns (uint[] memory) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).lastPriceList(tokenAddress, count);
    }

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(address tokenAddress, address paybackAddress) 
    override
    external 
    payable 
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).latestPriceAndTriggeredPriceInfo(tokenAddress);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    ///999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(
        address tokenAddress, 
        uint count, 
        address paybackAddress
    ) external payable override 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {

        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).lastPriceListAndTriggeredPriceInfo(tokenAddress, count);
    }

    /// @dev Get the latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress, address paybackAddress) external payable override returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice2(tokenAddress);
    }

    /// @dev Get the full information of latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @param paybackAddress As the charging fee may change, it is suggested that the caller pay more fees, 
    /// and the excess fees will be returned through this address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    ///         it means that the volatility has exceeded the range that can be expressed
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    /// @return ntokenAvgPrice Average price of ntoken
    /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo2(address tokenAddress, address paybackAddress) external payable override returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice,
         uint sigmaSQ, 
         uint ntokenBlockNumber, 
         uint ntokenPrice, 
         uint ntokenAvgPrice, 
         uint ntokenSigmaSQ
        ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo2(tokenAddress);
    }

    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress, address paybackAddress) external payable override returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
        
        Config memory config = _config;
        require(_addressFlags[msg.sender] == uint(config.normalFlag), "NestPriceFacade:!flag");
        _pay(tokenAddress, config.doubleFee, paybackAddress);
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice2(tokenAddress);
    }

    /* ========== INestQuery ========== */

    /// @dev Get the latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function triggeredPrice(
        address tokenAddress
    ) external view override noContract returns (
        uint blockNumber, 
        uint price
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice(tokenAddress);
    }

    /// @dev Get the full information of latest trigger price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo(address tokenAddress) external view override noContract returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo(tokenAddress);
    }

    /// @dev Find the price at block number
    /// @param tokenAddress Destination token address
    /// @param height Destination block number
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function findPrice(address tokenAddress, uint height) external view override noContract returns (
        uint blockNumber, 
        uint price
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).findPrice(tokenAddress, height);
    }

    /// @dev Get the latest effective price
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    function latestPrice(
        address tokenAddress
    ) external view override noContract returns (
        uint blockNumber, 
        uint price
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice(tokenAddress);
    }

    /// @dev Get the last (num) effective price
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return An array which length is num * 2, each two element expresses one price like blockNumber｜price
    function lastPriceList(
        address tokenAddress, 
        uint count
    ) external view override noContract returns (
        uint[] memory
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).lastPriceList(tokenAddress, count);
    }

    /// @dev Returns the results of latestPrice() and triggeredPriceInfo()
    /// @param tokenAddress Destination token address
    /// @return latestPriceBlockNumber The block number of latest price
    /// @return latestPriceValue The token latest price. (1eth equivalent to (price) token)
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function latestPriceAndTriggeredPriceInfo(address tokenAddress)
    override
    external 
    view
    noContract
    returns (
        uint latestPriceBlockNumber, 
        uint latestPriceValue,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).latestPriceAndTriggeredPriceInfo(tokenAddress);
    }

    /// @dev Returns lastPriceList and triggered price info
    /// @param tokenAddress Destination token address
    /// @param count The number of prices that want to return
    /// @return prices An array which length is num * 2, each two element expresses one price like blockNumber｜price
    /// @return triggeredPriceBlockNumber The block number of triggered price
    /// @return triggeredPriceValue The token triggered price. (1eth equivalent to (price) token)
    /// @return triggeredAvgPrice Average price
    /// @return triggeredSigmaSQ The square of the volatility (18 decimal places). The current implementation 
    /// assumes that the volatility cannot exceed 1. Correspondingly, when the return value is equal to 
    /// 999999999999996447, it means that the volatility has exceeded the range that can be expressed
    function lastPriceListAndTriggeredPriceInfo(address tokenAddress, uint count) external view override 
    returns (
        uint[] memory prices,
        uint triggeredPriceBlockNumber,
        uint triggeredPriceValue,
        uint triggeredAvgPrice,
        uint triggeredSigmaSQ
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).lastPriceListAndTriggeredPriceInfo(tokenAddress, count);
    }

    /// @dev Get the latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function triggeredPrice2(address tokenAddress) external view override noContract returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPrice2(tokenAddress);
    }

    /// @dev Get the full information of latest trigger price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return avgPrice Average price
    /// @return sigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that 
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447, 
    ///         it means that the volatility has exceeded the range that can be expressed
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    /// @return ntokenAvgPrice Average price of ntoken
    /// @return ntokenSigmaSQ The square of the volatility (18 decimal places). The current implementation assumes that
    ///         the volatility cannot exceed 1. Correspondingly, when the return value is equal to 999999999999996447,
    ///         it means that the volatility has exceeded the range that can be expressed
    function triggeredPriceInfo2(address tokenAddress) external view override noContract returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ, 
        uint ntokenBlockNumber, 
        uint ntokenPrice, 
        uint ntokenAvgPrice, 
        uint ntokenSigmaSQ
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).triggeredPriceInfo2(tokenAddress);
    }

    /// @dev Get the latest effective price. (token and ntoken)
    /// @param tokenAddress Destination token address
    /// @return blockNumber The block number of price
    /// @return price The token price. (1eth equivalent to (price) token)
    /// @return ntokenBlockNumber The block number of ntoken price
    /// @return ntokenPrice The ntoken price. (1eth equivalent to (price) ntoken)
    function latestPrice2(address tokenAddress) external view override noContract returns (
        uint blockNumber, 
        uint price, 
        uint ntokenBlockNumber, 
        uint ntokenPrice
    ) {
        return INestQuery(_getNestQuery(tokenAddress)).latestPrice2(tokenAddress);
    }
}