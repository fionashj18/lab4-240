// `default_nettype none

module masterPatternLoad (
  input  logic [1:0]  ShapeLocation,
  input  logic [2:0]  LoadShape,
  input  logic        LoadShapeNow, clock, clr,
  output logic [11:0] masterPattern,
  output logic        FinishLoading
);

  logic [3:0] loaded;
  logic [3:0] location;
  logic LoadShapeNow_sync;

  Synchronizer #(1) syn(.async(LoadShapeNow), .sync(LoadShapeNow_sync), .clock);
  // Finding which location shape goes to using Decoder
  Decoder #(4) dec (.I(ShapeLocation), 
                    .en(LoadShapeNow_sync), 
                    .D(location));

  // Inputs for DFF (OR with feedback keeps loaded bits set once high)
  logic d0, d1, d2, d3;
  assign d0 = location[0] | loaded[0];
  assign d1 = location[1] | loaded[1];
  assign d2 = location[2] | loaded[2];
  assign d3 = location[3] | loaded[3];

  // Register enable
  logic enR0, enR1, enR2, enR3;
  assign enR0 = location[0] & ~loaded[0];
  assign enR1 = location[1] & ~loaded[1];
  assign enR2 = location[2] & ~loaded[2];
  assign enR3 = location[3] & ~loaded[3];

  // DFFs to track which locations have been loaded
  DFlipFlop dff0 (.D(enR0 | loaded[0]), .reset_L(~clr), .clock(clock),
                  .preset_L(1'b1), .Q(loaded[0]));
  DFlipFlop dff1 (.D(enR1 | loaded[1]), .reset_L(~clr), .clock(clock),
                  .preset_L(1'b1), .Q(loaded[1]));
  DFlipFlop dff2 (.D(enR2 | loaded[2]), .reset_L(~clr), .clock(clock),
                  .preset_L(1'b1), .Q(loaded[2]));
  DFlipFlop dff3 (.D(enR3 | loaded[3]), .reset_L(~clr), .clock(clock),
                  .preset_L(1'b1), .Q(loaded[3]));


  // Registers storing the shape for each location
  Register #(3) reg0 (.D(LoadShape), .en(enR0), .clear(clr),
                      .clock(clock), .Q(masterPattern[2:0]));
  Register #(3) reg1 (.D(LoadShape), .en(enR1), .clear(clr),
                      .clock(clock), .Q(masterPattern[5:3]));
  Register #(3) reg2 (.D(LoadShape), .en(enR2), .clear(clr),
                      .clock(clock), .Q(masterPattern[8:6]));
  Register #(3) reg3 (.D(LoadShape), .en(enR3), .clear(clr),
                      .clock(clock), .Q(masterPattern[11:9]));

  // Checking all patterns are loaded
  Comparator #(4) comp (.A(4'b1111), .B(loaded), .AeqB(FinishLoading));

endmodule : masterPatternLoad