/// 9×9 board geometry. Cells are indexed 0..80 row by row.
library;

/// Row of each cell.
final List<int> rowOf = List.unmodifiable([for (var i = 0; i < 81; i++) i ~/ 9]);

/// Column of each cell.
final List<int> colOf = List.unmodifiable([for (var i = 0; i < 81; i++) i % 9]);

/// 3×3 block of each cell (0..8, row by row).
final List<int> blockOf = List.unmodifiable([
  for (var i = 0; i < 81; i++) (i ~/ 27) * 3 + (i % 9) ~/ 3,
]);

/// Orthogonal neighbours in the JS order: up, down, left, right.
final List<List<int>> neighbours = List.unmodifiable([
  for (var i = 0; i < 81; i++)
    List<int>.unmodifiable([
      if (i ~/ 9 > 0) i - 9,
      if (i ~/ 9 < 8) i + 9,
      if (i % 9 > 0) i - 1,
      if (i % 9 < 8) i + 1,
    ]),
]);

/// The 27 houses: rows 0..8, columns 9..17, blocks 18..26.
final List<List<int>> houses = List.unmodifiable([
  for (var r = 0; r < 9; r++)
    List<int>.unmodifiable([for (var c = 0; c < 9; c++) r * 9 + c]),
  for (var c = 0; c < 9; c++)
    List<int>.unmodifiable([for (var r = 0; r < 9; r++) r * 9 + c]),
  for (var b = 0; b < 9; b++)
    List<int>.unmodifiable([
      for (var i = 0; i < 81; i++)
        if (blockOf[i] == b) i,
    ]),
]);

/// Cells sharing a row, column or block with each cell (excluding itself).
final List<List<int>> peers = List.unmodifiable([
  for (var i = 0; i < 81; i++)
    List<int>.unmodifiable([
      for (var j = 0; j < 81; j++)
        if (j != i &&
            (rowOf[j] == rowOf[i] ||
                colOf[j] == colOf[i] ||
                blockOf[j] == blockOf[i]))
          j,
    ]),
]);
