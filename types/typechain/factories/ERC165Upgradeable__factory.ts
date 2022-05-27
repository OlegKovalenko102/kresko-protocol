/* Autogenerated file. Do not edit manually. */
// @ts-nocheck
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer, utils } from "ethers";
import { Provider } from "@ethersproject/providers";
import type {
  ERC165Upgradeable,
  ERC165UpgradeableInterface,
} from "../ERC165Upgradeable";

const _abi = [
  {
    anonymous: false,
    inputs: [
      {
        indexed: false,
        internalType: "uint8",
        name: "version",
        type: "uint8",
      },
    ],
    name: "Initialized",
    type: "event",
  },
  {
    inputs: [
      {
        internalType: "bytes4",
        name: "interfaceId",
        type: "bytes4",
      },
    ],
    name: "supportsInterface",
    outputs: [
      {
        internalType: "bool",
        name: "",
        type: "bool",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

export class ERC165Upgradeable__factory {
  static readonly abi = _abi;
  static createInterface(): ERC165UpgradeableInterface {
    return new utils.Interface(_abi) as ERC165UpgradeableInterface;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): ERC165Upgradeable {
    return new Contract(address, _abi, signerOrProvider) as ERC165Upgradeable;
  }
}
