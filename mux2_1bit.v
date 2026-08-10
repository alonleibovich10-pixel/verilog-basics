module mux2 (
    input wire a,
    input wire b,
    input wire sel,
    output wire out
);

    // תנאי לוגי פשוט: אם sel=1 בחר ב-b, אחרת בחר ב-a
    assign out = sel ? b : a;

endmodule
