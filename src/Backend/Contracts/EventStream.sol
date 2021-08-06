// SPDX-License-Identifier: MIT

pragma solidity ^0.7.1;

/** EventStream:
  * An EventStream exists independently of Jobs and exists to group Real-World Events
  * Every time we want to start capturing a new sequence of events, we instantiate a new event stream
  * Jobs can be connected to event streams by referencing the stream ID
  * Individual events are not stored on the blockchain, but instead can be viewed in IPFS
 **/ 

contract EventStreamFactory {

  enum Status {open, paused, closed}

  struct EventStream {
    string name;
    Status streamStatus;
    string[] eventCIDs;
  }
  
  EventStream[] eventStreams;

  event StreamCreated(string name, creator, uint eventStreamId);

  function createEventStream(string _name) public {
    eventStreams.push(EventStream({
        name: _name,
        streamStatus: Status.open    
      }));
      uint eventStreamId = eventStreams.length - 1;
      emit StreamCreated(_name, eventStreamId);
  }
}