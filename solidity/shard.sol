// SPDX-License-Identifier: MIT

/*
MIT License
Copyright (c) 2021 Paladin10

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:
The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/

//https://github.com/andrecronje/rarity/blob/main/core/rarity.sol
//https://etherscan.io/address/0xf3dfbe887d81c442557f7a59e3a0aecf5e39f6aa#code


pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library StringWork {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function toBase64 (bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }

    function uintToString (uint256 value) 
        internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function bytes32ToString(bytes32 data) 
        public
        pure
        returns (string memory result) 
    {
        bytes memory temp = new bytes(65);
        uint256 count;

        for (uint256 i = 0; i < 32; i++) {
            bytes1 currentByte = bytes1(data << (i * 8));
            
            uint8 c1 = uint8(
                bytes1((currentByte << 4) >> 4)
            );
            
            uint8 c2 = uint8(
                bytes1((currentByte >> 4))
            );
        
            if (c2 >= 0 && c2 <= 9) temp[++count] = bytes1(c2 + 48);
            else temp[++count] = bytes1(c2 + 87);
            
            if (c1 >= 0 && c1 <= 9) temp[++count] = bytes1(c1 + 48);
            else temp[++count] = bytes1(c1 + 87);
        }
        
        result = string(temp);
    }
}

interface IJSON {
    function properties (bytes32 seed) external view returns (bytes memory);
    function propertiesString (bytes32 seed) external view returns (string memory);
    function tokenURI(bytes32 seed) external view returns (string memory); 
}

contract ShardGenerator is IJSON {
    /*
        Internal functions 
    */

    function hash(bytes32 seed, string memory toHash)
        internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(seed,toHash));
    }

    //pull a random number 
    function _rnd(bytes32 _hash, uint256 n) 
        internal pure returns (uint256)
    {
        return uint256(_hash) % n;
    }

    //Roll a number of dice 
    function _d(bytes32 _hash, uint256 n, uint256 dx) 
        internal pure returns (uint256 r)
    {
        for(uint256 i = 0; i < n; i++){
            r += uint256(uint8(_hash[i])) % dx;
        }
    }
    
    /*
        Generators
    */

    /*
        CLIMATE
    */
    uint[16] private CLIMATEID = [0,1,1,1,2,2,2,2,3,3,3,3,4,4,4,4];
    string[5] private CLIMATE = ["Arctic", "Sub-arctic", "Temperate","Sub-tropical","Tropical"];

    function getClimate(bytes32 seed) 
        public view returns (string memory)
    {
        return CLIMATE[CLIMATEID[_rnd(hash(seed,"climate"),16)]];
    }

    /*
        RAINFALL
    */
    string[4] private RAINFALL = ["Arid","Standard","Seasonal","Rainy"];

    function getRainfall(bytes32 seed) 
        public view returns (string memory)
    {
        return RAINFALL[_rnd(hash(seed,"rainfall"),4)];
    }

    /*
        TERRAIN
    */
    string[6] private TERRAIN_COMMON = ["Forest","Foothills","Plains","Riverside","Lakeshore","Island"];
    string[7] private TERRAIN_UNCOMMON = ["Mountains","Valley","Swamp","Costal Beach","Costal Cliffs","Mangroves","Costal Shallows"];
    string[8] private TERRAIN_RARE = ["High Mountains","Highland Plateau","Mesas","Scrub","Dry Lakebed","Chasm","Atoll","Costal Reefs"];
    string[7] private TERRAIN_VERYRARE = ["Caldera","Volcano","Deep Ocean","Underground Mammoth Cavern","Underground Cavern Network","Underground River","Underground Lake"];

    function getTerrain(bytes32 seed) 
        public view returns (string memory)
    {
        uint256 p = _rnd(hash(seed,"terrain-rarity"),32);
        bytes32 tHash = hash(seed,"terrain");
        //common
        if(p < 16){
            return TERRAIN_COMMON[_rnd(tHash,6)];
        }
        //uncommon
        else if (p < 26){
            return TERRAIN_UNCOMMON[_rnd(tHash,7)];
        }
        //rare
        else if (p<31){
            return TERRAIN_RARE[_rnd(tHash,8)];
        }
        //very rare 
        else {
            return TERRAIN_VERYRARE[_rnd(tHash,7)];
        }
    }

    /*
        FEATURE of the shard  
    */
    uint256[16] private FEATUREID = [0,0,0,0,0,1,1,1,1,2,2,2,3,3,4,5];
    string[6] private FEATURE = ["Region","Hazard","Obstacle","Resource","Landmark","Dungeon"];
    //shard feature determines size
    uint256[3][6] private SIZE = [[3,8,2],[3,8,2],[3,8,0],[4,8,2],[2,4,0],[1,4,0]];

    function getFeature(bytes32 seed) 
        public view returns (string memory)
    {
        return FEATURE[FEATUREID[_rnd(hash(seed,"feature"),16)]];
    }

    function getSize(bytes32 seed) 
        public view returns (uint256)
    {
        uint256 i = FEATUREID[_rnd(hash(seed,"feature"),16)];
        return _d(hash(seed,"size"),SIZE[i][0],SIZE[i][1]) + SIZE[i][2];
    }

    /*
        External
    */
    function randomHash () 
        public view returns (bytes32) 
    {
        return keccak256(abi.encodePacked(address(this),msg.sender,block.timestamp));
    }

    //must use plain encode so that strings can be decoded 
    function properties (bytes32 seed) 
        override public view returns(bytes memory)
    {
        return abi.encode(getClimate(seed),getRainfall(seed),getTerrain(seed),getFeature(seed),getSize(seed));
    }

    //pack as string for human readable result
    function propertiesString (bytes32 seed) 
        override public view returns(string memory)
    {
        return string(abi.encodePacked(getClimate(seed),",",getRainfall(seed),",",getTerrain(seed),",",getFeature(seed),",",StringWork.uintToString(getSize(seed))));
    }

    function _SVGData(bytes32 seed) internal view returns (string[11] memory parts) {
        parts[0] = string(abi.encodePacked("seed:"," ",StringWork.bytes32ToString(seed)));

        parts[1] = '</text><text x="10" y="40" class="base">';
        
        parts[2] = string(abi.encodePacked("climate:"," ",getClimate(seed)));

        parts[3] = '</text><text x="10" y="60" class="base">';

        parts[4] = string(abi.encodePacked("rainfall:"," ",getRainfall(seed)));

        parts[5] = '</text><text x="10" y="80" class="base">';

        parts[6] = string(abi.encodePacked("terrain:"," ",getTerrain(seed)));

        parts[7] = '</text><text x="10" y="100" class="base">';

        parts[8] = string(abi.encodePacked("feature:"," ",getFeature(seed)));

        parts[9] = '</text><text x="10" y="120" class="base">';

        parts[10] = string(abi.encodePacked("size:"," ",StringWork.uintToString(getSize(seed))));
    }

    function tokenURI(bytes32 seed) override public view returns (string memory) {
        string[11] memory parts = _SVGData(seed);
        string[2] memory wrapper; 

        wrapper[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 150 150"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        wrapper[1] = '</text></svg>';

        string memory data = string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6],parts[7],parts[8],parts[9],parts[10]));
        string memory output = string(abi.encodePacked(wrapper[0],data,wrapper[1]));

        return output;
    }
}

contract Shard is ERC721PresetMinterPauserAutoId {
    string internal BASE;
    IJSON internal Gen;
    uint256 public COST = 1 ether;

    //keeps the timestamp of every shard created 
    mapping (uint256 => bytes32) public seed; 

    event Withdrawal (address indexed who, uint256 amt);

    /*
        ADMIN
    */
    /**
     * @dev Performs withdraw of balance of the contract to the bank
     */
    function withdraw ()
        public
    {
        address payable user = payable(_msgSender());
        require(hasRole(DEFAULT_ADMIN_ROLE, user), "Shard: must have admin role to withdraw");
        
        //get balance 
        uint256 balance = address(this).balance;
        
        //Withdraw
        user.transfer(balance);
        
        emit Withdrawal(user, balance);
    }
    
    /**
     * @dev Sets a address/721 with a cost 
     */
    function setCost (uint256 _cost)
        public
    {
        require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()), "Catalog: must have admin role to set cost");
        
        COST = _cost;
    }

    /*
        External
    */
    //reply with JSON data provided by main generator function 
    function tokenURI(uint256 tokenId) override public view returns (string memory) {
        require(seed[tokenId] != bytes32(0),"Shard: Token does not exist.");

        string memory output = Gen.tokenURI(seed[tokenId]);
        
        string memory json = StringWork.toBase64(bytes(string(abi.encodePacked('{"name": "EVMOS Shard #', StringWork.uintToString(tokenId), '", "description": "One of the many shards in the COSMOS. A place of exploration and adventure.", "image": "data:image/svg+xml;base64,', StringWork.toBase64(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output; 
    }

    /**
     * @dev Removes Burn capability
     */
    function burn(uint256 tokenId) 
        public override 
    {}

    function claim()
        public payable
        returns (uint256)
    {
        require(msg.value >= COST, "Shard: did not provide enough funds");

        address player = msg.sender; 
        uint256 newItemId = totalSupply();
        _safeMint(player, newItemId);
        //set seed for use in generation later
        seed[newItemId] = keccak256(abi.encodePacked(BASE,address(this),newItemId,player,block.timestamp));

        return newItemId;
    }

    constructor(string memory base, IJSON _gen) ERC721PresetMinterPauserAutoId("Shards of EVMOS", "SHD.EVMOS", "") {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        BASE = base;
        Gen = _gen;
    }
}

