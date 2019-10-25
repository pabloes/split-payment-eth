pragma solidity 0.5.11;
import "https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/math/SafeMath.sol";
//TODO overflow
//TODO reentrance

contract DonationEth {
    using SafeMath for uint256;

    uint balance;
    uint totalDonated;
    address[] addresses;
    mapping(address => bool) between;
    mapping(address => uint256) withdrawals;
    mapping(address => uint8) rates;
    mapping(address => uint256) autoMin; //minimum amount to automatically transfer share on pay //TODO

    constructor (address[] memory _addresses, uint8[] memory _rates) public {
        balance = 0;
        totalDonated = 0;
        addresses = _addresses;

        for (uint i = 0; i < _addresses.length; i++) {
            address currentAddress = _addresses[i];
            between[currentAddress] = true;
            withdrawals[currentAddress] = 0;
            rates[currentAddress] = _rates[i];
            autoMin[currentAddress] = 100000000000000000;
        }
    }

    function () external payable {
        //TODO handle overflow
        balance = balance.add(msg.value);
        totalDonated = totalDonated.add(msg.value);

        for (uint i = 0; i < addresses.length; i++) {
            if(getAvailable(addresses[i]) > autoMin[addresses[i]]){
                doWithdraw(addresses[i]); //TODO optimize: getAvailable 2 times executed
            }
        }
    }

    function getAutoMin() public view returns (uint256) {
        require(between[msg.sender]);
        return autoMin[msg.sender];
    }

    function setAutoMin(uint256 autoMinAmount) public{
        require(between[msg.sender]);
        autoMin[msg.sender] = autoMinAmount;
    }

    function taken() public view returns (uint256) {
        return withdrawals[msg.sender];
    }

    function  available() public view returns (uint256) {
        require(between[msg.sender]);

        //return (totalDonated * rates[msg.sender] / 100) - withdrawals[msg.sender];
        return getAvailable(msg.sender);
    }

    function getAvailable(address addr) private view returns (uint256){
        return (totalDonated.mul(rates[addr]).div(100)).sub(withdrawals[addr]);
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function getTotalDonation() public view returns (uint256) {
        return totalDonated;
    }

    function withdraw() public  {
        require(between[msg.sender]);
        doWithdraw(msg.sender);
    }

    function doWithdraw(address addr) private {
        uint withdrawAmount = getAvailable(addr);

        require(withdrawAmount > 0, "avaiable > 0");

        //withdrawals[msg.sender] += withdrawAmount
        withdrawals[addr] = withdrawals[addr].add(withdrawAmount);
        balance = balance.sub(withdrawAmount);
        //TODO assert reentrance?
        address(uint160(addr)).transfer(withdrawAmount);
    }
}