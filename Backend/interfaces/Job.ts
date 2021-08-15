import { BigNumber } from "ethers";

export interface Job {
  creator: string;
  amount: BigNumber;
  refreshRate: BigNumber;
  eventsRecorded: BigNumber;
  creatorSigned: boolean;
  applicantSigned: boolean;
  workSubmitted: boolean;
  state: number;
  eventStreamId: BigNumber;
}
