// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

// Bank 合约
contract BankExample {

    mapping(address => uint256) public bankInfo; // 存储账户余额
    Depositor [3] public top3;  //存款TOP3
    struct Depositor {
        address account;
        uint256 money;
    }

    // 设置管理员
    address admin;
    constructor(address payable _admin) {
        admin = _admin;
    }

    // 获取余额
    function getBalance() public view returns (uint256, uint256) {
        return (msg.sender.balance, address(this).balance);
    }
    
    // 获取存款信息
    function getDeposit() public view returns (uint256) {
        return bankInfo[msg.sender];
    }
    
    // 管理员取款
    function withdraw() public payable {
        require(admin == tx.origin, "Only administrators can call this function");
        uint256 amount = address(this).balance;
        payable(admin).transfer(amount);
    }

    // 合约存款
    receive() external payable {
        if (bankInfo[msg.sender] == 0) {
            bankInfo[msg.sender] = msg.value;
        } else {
            bankInfo[msg.sender] += msg.value;
        }

         // 如果金额小于第三名且前三名都已满，则直接返回
        if (bankInfo[msg.sender] <= top3[2].money && top3[2].account != address(0)) {
            return;
        }
        // 查找插入位置
        int8 insertPosition = -1;
        for (uint8 i = 0; i < 3; i++) {
            if (bankInfo[msg.sender] > top3[i].money || top3[i].account == address(0)) {
                insertPosition = int8(i);
                break;
            }
        }
        // 如果找到插入位置
        if (insertPosition >= 0) {
            // 向后移动元素
            for (uint8 j = 2; j > uint8(insertPosition); j--) {
                top3[j] = top3[j - 1];
            }
            // 插入新记录
            top3[uint8(insertPosition)] = Depositor(msg.sender, bankInfo[msg.sender]);
        }
    }

}