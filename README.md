# starknet-tokens-showdown

This repo illustrates the difference in gas costs when using a Uint256 and a felt based token on StarkNet.

It contains two ERC20 implementations:

* the `uint` one is a copy of OpenZeppelin's ERC20, v0.3.1
* the `afelt` one is based on the OZ token with a slight modification of completely dropping the use of `Uint256` and replacing if with `felt`s everywhere

I used the standard testing framework to gather the transaction execution resources. The cost calculation is using [v.0.8.0](https://docs.starknet.io/docs/Fees/fee-mechanism/) fees and does not take into account storage costs as those would be the same (assuming values less than 2^128).

Here is the breakdown:

#### approve

```sh
# pytest -s tests/uint/test_ERC20.py::test_approve

tests/uint/test_ERC20.py Uint256 test_approve
ExecutionResources(n_steps=501, builtin_instance_counter={'pedersen_builtin': 2, 'range_check_builtin': 10, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=17)
Gas cost: 55.45

# pytest -s tests/afelt/test_ERC20.py::test_approve

tests/afelt/test_ERC20.py felt test_approve
ExecutionResources(n_steps=470, builtin_instance_counter={'pedersen_builtin': 2, 'range_check_builtin': 6, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=16)
Gas cost: 52.3
```

#### transfer

```sh
# pytest -s tests/uint/test_ERC20.py::test_transfer

tests/uint/test_ERC20.py Uint256 test_transfer
ExecutionResources(n_steps=889, builtin_instance_counter={'pedersen_builtin': 4, 'range_check_builtin': 32, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=46)
Gas cost: 84.45000000000002

# pytest -s tests/afelt/test_ERC20.py::test_transfer

tests/afelt/test_ERC20.py felt test_transfer
ExecutionResources(n_steps=673, builtin_instance_counter={'pedersen_builtin': 4, 'range_check_builtin': 17, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=80)
Gas cost: 67.65
```

#### transferFrom

```sh
# pytest -s tests/uint/test_ERC20.py::test_transferFrom
tests/uint/test_ERC20.py Uint256 test_transferFrom
ExecutionResources(n_steps=1305, builtin_instance_counter={'pedersen_builtin': 8, 'range_check_builtin': 51, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=67)
Gas cost: 114.45

# pytest -s tests/afelt/test_ERC20.py::test_transferFrom
tests/afelt/test_ERC20.py felt test_transferFrom
ExecutionResources(n_steps=905, builtin_instance_counter={'pedersen_builtin': 8, 'range_check_builtin': 25, 'ecdsa_builtin': 1, 'bitwise_builtin': 0, 'output_builtin': 0}, n_memory_holes=138)
Gas cost: 84.05000000000001
````

## Results

Cost values from the results above are rounded-up:

|             | approve | transfer | transferFrom |
|-------------|---------|----------|--------------|
| Uint256     | 56      | 85       | 115          |
| felt        | 53      | 68       | 85           |
| savings (%) | 5.3     | 20       | 26           |
