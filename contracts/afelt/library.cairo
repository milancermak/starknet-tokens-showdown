# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.3.1 (token/erc20/library.cairo)

%lang starknet

from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_lt, assert_le_felt
from starkware.cairo.common.bool import FALSE

#
# Events
#

@event
func Transfer(from_ : felt, to : felt, value : felt):
end

@event
func Approval(owner : felt, spender : felt, value : felt):
end

#
# Storage
#

@storage_var
func ERC20_name() -> (name : felt):
end

@storage_var
func ERC20_symbol() -> (symbol : felt):
end

@storage_var
func ERC20_decimals() -> (decimals : felt):
end

@storage_var
func ERC20_total_supply() -> (total_supply : felt):
end

@storage_var
func ERC20_balances(account : felt) -> (balance : felt):
end

@storage_var
func ERC20_allowances(owner : felt, spender : felt) -> (allowance : felt):
end

namespace ERC20:
    #
    # Initializer
    #

    func initializer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        name : felt, symbol : felt, decimals : felt
    ):
        ERC20_name.write(name)
        ERC20_symbol.write(symbol)
        with_attr error_message("ERC20: decimals exceed 2^8"):
            assert_lt(decimals, 256)
        end
        ERC20_decimals.write(decimals)
        return ()
    end

    #
    # Public functions
    #

    func name{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (name : felt):
        let (name) = ERC20_name.read()
        return (name)
    end

    func symbol{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        symbol : felt
    ):
        let (symbol) = ERC20_symbol.read()
        return (symbol)
    end

    func total_supply{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        total_supply : felt
    ):
        return ERC20_total_supply.read()
    end

    func decimals{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        decimals : felt
    ):
        let (decimals) = ERC20_decimals.read()
        return (decimals)
    end

    func balance_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt
    ) -> (balance : felt):
        return ERC20_balances.read(account)
    end

    func allowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, spender : felt
    ) -> (allowance : felt):
        return ERC20_allowances.read(owner, spender)
    end

    func transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, amount : felt
    ):
        let (sender) = get_caller_address()
        _transfer(sender, recipient, amount)
        return ()
    end

    func transfer_from{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, amount : felt
    ) -> ():
        let (caller) = get_caller_address()
        # subtract allowance
        _spend_allowance(sender, caller, amount)
        # execute transfer
        _transfer(sender, recipient, amount)
        return ()
    end

    func approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        spender : felt, amount : felt
    ):
        let (caller) = get_caller_address()
        _approve(caller, spender, amount)
        return ()
    end

    #
    # Internal
    #

    func _mint{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        recipient : felt, amount : felt
    ):
        with_attr error_message("ERC20: cannot mint to the zero address"):
            assert_not_zero(recipient)
        end

        let (supply : felt) = ERC20_total_supply.read()
        let new_supply : felt = supply + amount
        with_attr error_message("ERC20: mint overflow"):
            assert_le_felt(supply, new_supply)
        end
        ERC20_total_supply.write(new_supply)

        let (balance : felt) = ERC20_balances.read(account=recipient)
        let new_balance : felt = balance + amount
        ERC20_balances.write(recipient, new_balance)

        Transfer.emit(0, recipient, amount)
        return ()
    end

    func _burn{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt, amount : felt
    ):
        with_attr error_message("ERC20: cannot burn from the zero address"):
            assert_not_zero(account)
        end

        let (balance : felt) = ERC20_balances.read(account)
        with_attr error_message("ERC20: burn amount exceeds balance"):
            let new_balance : felt = balance - amount
            assert_le_felt(new_balance, balance)
        end

        ERC20_balances.write(account, new_balance)

        let (supply : felt) = ERC20_total_supply.read()
        let new_supply : felt = supply - amount
        ERC20_total_supply.write(new_supply)
        Transfer.emit(account, 0, amount)
        return ()
    end

    func _transfer{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        sender : felt, recipient : felt, amount : felt
    ):
        with_attr error_message("ERC20: cannot transfer from the zero address"):
            assert_not_zero(sender)
        end

        with_attr error_message("ERC20: cannot transfer to the zero address"):
            assert_not_zero(recipient)
        end

        let (sender_balance : felt) = ERC20_balances.read(account=sender)
        let new_sender_balance =  sender_balance - amount
        with_attr error_message("ERC20: transfer amount exceeds balance"):
            assert_le_felt(new_sender_balance, sender_balance)
        end

        ERC20_balances.write(sender, new_sender_balance)

        # add to recipient
        let (recipient_balance : felt) = ERC20_balances.read(account=recipient)
        let new_recipient_balance = recipient_balance + amount
        ERC20_balances.write(recipient, new_recipient_balance)
        Transfer.emit(sender, recipient, amount)
        return ()
    end

    func _approve{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, spender : felt, amount : felt
    ):
        with_attr error_message("ERC20: cannot approve from the zero address"):
            assert_not_zero(owner)
        end

        with_attr error_message("ERC20: cannot approve to the zero address"):
            assert_not_zero(spender)
        end

        ERC20_allowances.write(owner, spender, amount)
        Approval.emit(owner, spender, amount)
        return ()
    end

    func _spend_allowance{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        owner : felt, spender : felt, amount : felt
    ):
        alloc_locals

        let (current_allowance : felt) = ERC20_allowances.read(owner, spender)
        if current_allowance != -1:
            let new_allowance = current_allowance - amount
            with_attr error_message("ERC20: insufficient allowance"):
                assert_le_felt(new_allowance, current_allowance)
            end

            _approve(owner, spender, new_allowance)
            return ()

        end

        return ()
    end
end
