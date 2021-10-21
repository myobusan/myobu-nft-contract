// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract MyobuNFT is ERC721Enumerable, Ownable {

    using Strings for uint256;

    string _baseTokenURI = "https://app.myobu.io/metadata/";
    uint256 private _teamReserved = 100; //reserve NFTs for giveaways
    uint256 private _price = 0.05 ether;
    uint256 private _maxNFTPerWallet = 20;
    uint256 private _maxSupply = 10000;
    bool public _saleOpen = false;

    // withdraw addresses
    address t1 = 0x97fDEf5b5e3285592068316ae4FB453D12f83f03;

    modifier canWithdraw(){
        require(address(this).balance > 0.2 ether);
        _;
    }

    struct ContractOwners {
        address payable addr;
        uint percent;
    }

    ContractOwners[] _contractOwners;

    constructor() ERC721("MyobuNFT", unicode"MYŌBU")  {
        _contractOwners.push(ContractOwners(payable(address(t1)), 100));
    }

    function mintMyobu(uint256 num) public payable {
        uint256 supply = totalSupply();
        require( _saleOpen,                                         "Sale not open yet" );
        require( num < _maxNFTPerWallet,                            "You've reached maximum number of NFTs" );
        require( supply + num < _maxSupply - _teamReserved,         "Exceeds maximum Myobu supply" );
        require( msg.value >= _price * num,                         "Ether sent is lower than expected" );

        for(uint256 i; i < num; i++){
            _safeMint( msg.sender, supply + i );
        }
    }

    function walletOfOwner(address _owner) public view returns(uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory tokensId = new uint256[](tokenCount);
        for(uint256 i; i < tokenCount; i++){
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    // In case ETH goes wild
    function setPrice(uint256 _newPrice) public onlyOwner() {
        _price = _newPrice;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function getPrice() public view returns (uint256){
        return _price;
    }

    function giveAway(address _to, uint256 _amount) external onlyOwner() {
        require( _amount <= _teamReserved, "Exceeds reserved Myobu supply" );

        uint256 supply = totalSupply();
        for(uint256 i; i < _amount; i++){
            _safeMint( _to, supply + i );
        }

        _teamReserved -= _amount;
    }

    function openSale(bool val) public onlyOwner {
        _saleOpen = val;
    }

    function withdraw() external payable onlyOwner() canWithdraw() {
        uint nbalance = address(this).balance - 0.1 ether;
        for(uint i = 0; i < _contractOwners.length; i++){
            ContractOwners storage o = _contractOwners[i];
            o.addr.transfer((nbalance * o.percent) / 100);
        }
    }
}