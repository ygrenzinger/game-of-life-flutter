import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';


enum CellState {
  ALIVE, DEAD
}

extension CellStateExtension on CellState {

  CellState nextState(int numberOfAliveNeighbours) {
    if (numberOfAliveNeighbours == 3) {
      return CellState.ALIVE;
    }
    if (this == CellState.ALIVE && numberOfAliveNeighbours == 2) {
      return CellState.ALIVE;
    }
    return CellState.DEAD;
  }

}

class Position {
  final int row;
  final int column;

  Position(this.row, this.column);

  @override
  String toString() {
    return '$row-$column';
  }

  @override
  bool operator ==(other) => other is Position && row == other.row && column == other.column;

  @override
  int get hashCode => Object.hash(row, column);

  operator +(Position p) => Position(row + p.row, column + p.column);
}

class GameOfLife {

  static final List<Position> neighbourShifts = [
    Position(-1, -1), Position(-1, 0), Position(-1, -1),
    Position(0, -1), Position(0, -1),
    Position(1, -1), Position(1, 0), Position(1, -1),
  ];

  final int size;
  final Set<Position> _aliveCells;
  GameOfLife(this.size, this._aliveCells);

  static GameOfLife of(int size, {bool random = false}) {
    Set<Position> aliveCells = {};
    if (random) {
      for (int row = 0; row < size; row++) {
        for (int column = 0; column < size; column++) {
          var number = Random().nextInt(2);
          if (number % 2 == 0) {
            aliveCells.add(Position(row, column));
          }
        }
      }
    }

    return GameOfLife(size, aliveCells);
  }
  
  bool isAlive(Position position) =>
    _aliveCells.contains(position);

  CellState cellStateAt(Position position) {
    if (isAlive(position)) {
      return CellState.ALIVE;
    } else {
      return CellState.DEAD;
    }
  }

  GameOfLife switchCellState(Position position) {
    var updatedCells = Set<Position>.from(_aliveCells);
    if (isAlive(position)) {
      updatedCells.remove(position);
    } else {
      updatedCells.add(position);
    }
    return GameOfLife(size, updatedCells);
  }

  bool isInGrid(Position position) =>
      position.row >= 0 && position.row < size
        && position.column >= 0 && position.column < size;

  GameOfLife nextGeneration() {
    Set<Position> nextCells = {};

    for (var position in _aliveCellsWithNeighbour()) {
      final cellState = cellStateAt(position);
      final numberOfAliveNeighbours = _computeAliveNeighbours(position);
      if (cellState.nextState(numberOfAliveNeighbours) == CellState.ALIVE) {
        nextCells.add(position);
      }
    }
    return GameOfLife(size, nextCells);
  }

  Set<Position> _aliveCellsWithNeighbour() {
    return _aliveCells.expand((position) => _blockAt(position)).toSet();
  }

  List<Position> _blockAt(Position position) {
    var block = _neighboursOf(position);
    block.add(position);
    return block;
  }
  
  int _computeAliveNeighbours(Position position)  =>
      _neighboursOf(position).fold(0, (int previousValue, Position position) {
        if (isAlive(position)) {
          return previousValue + 1;
        } else {
          return previousValue;
        }
      });

  List<Position> _neighboursOf(Position position) =>
      GameOfLife.neighbourShifts
        .map((Position p) => position + p as Position)
        .where(isInGrid)
        .toList();

}

class GameOfLifeWidget extends StatefulWidget {
  const GameOfLifeWidget({Key? key}) : super(key: key);

  @override
  State<GameOfLifeWidget> createState() => _GameOfLifeWidgetState();
}

class _GameOfLifeWidgetState extends State<GameOfLifeWidget> {
  Timer? generating;
  GameOfLife _gameOfLife = GameOfLife.of(50, random: true);

  void startRunning(){
    generating = Timer.periodic(const Duration(seconds: 1),(_) => startGeneration());
  }

  void stopRunning(){
    setState(() => generating?.cancel());
  }

  void startGeneration(){
    print("next generation");
    setState(() {
      _gameOfLife = _gameOfLife.nextGeneration();
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      startRunning();
    });
  }

  @override
  Widget build(BuildContext context) {
    var children = List<int>.generate(_gameOfLife.size, (i) => i).expand((row) => _buildRow(row)).toList();
    return GridView(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gameOfLife.size,
        ),
        children: children
    );
  }

  void _switchCellState(Position position) {
    setState(() => {
      _gameOfLife = _gameOfLife.switchCellState(position)
    });
  }

  GridCell _buildCell(int row, int column) {
    final position = Position(row, column);
    return GridCell(position: position, alive: _gameOfLife.isAlive(position), onCellClicked: _switchCellState);
  }

  List<GridCell> _buildRow(int row) {
    return List<int>.generate(_gameOfLife.size, (i) => i).map((column) => _buildCell(row, column)).toList();
  }
}

class GridCell extends StatelessWidget {
  GridCell({
    required this.position,
    required this.alive,
    required this.onCellClicked,
  }) : super(key: ObjectKey(position));

  final Position position;
  final bool alive;
  final Function(Position) onCellClicked;

  @override
  Widget build(BuildContext context) {
    //print('cell position $position alive $alive');
    return InkWell(
        child:
        Center(
          child: Container(
            margin: const EdgeInsets.all(1.0),
            width: 20.0,
            height: 20.0,
            decoration: BoxDecoration(
              color: alive ? Colors.black : Colors.white,
              border: Border.all(
                color: Colors.black,
                width: 1,
              ),
            ),
          ),
      ),
      onTap: () => onCellClicked(position),
    );
  }
}



void main() {
  runApp(
    const MaterialApp(
      home: Scaffold(
        body: Center(
          child: GameOfLifeWidget(),
        ),
      ),
    ),
  );
}