import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:appflowy_editor/src/editor/block_component/table_block_component/util.dart';
import 'package:flutter/material.dart';

final List<CommandShortcutEvent> tableCommands = [
  _enterInTableCell,
  _leftInTableCell,
  _rightInTableCell,
  _upInTableCell,
  _downInTableCell,
  _tabInTableCell,
  _backSpaceInTableCell,
];

final CommandShortcutEvent _enterInTableCell = CommandShortcutEvent(
  key: 'Don\'t add new line in table cell',
  command: 'enter',
  handler: _enterInTableCellHandler,
);

final CommandShortcutEvent _leftInTableCell = CommandShortcutEvent(
  key: 'Move to left cell if its at start of current cell',
  command: 'arrow left',
  handler: _leftInTableCellHandler,
);

final CommandShortcutEvent _rightInTableCell = CommandShortcutEvent(
  key: 'Move to right cell if its at the end of current cell',
  command: 'arrow right',
  handler: _rightInTableCellHandler,
);

final CommandShortcutEvent _upInTableCell = CommandShortcutEvent(
  key: 'Move to up cell at same offset',
  command: 'arrow up',
  handler: _upInTableCellHandler,
);

final CommandShortcutEvent _downInTableCell = CommandShortcutEvent(
  key: 'Move to down cell at same offset',
  command: 'arrow down',
  handler: _downInTableCellHandler,
);

final CommandShortcutEvent _tabInTableCell = CommandShortcutEvent(
  key: 'Navigate around the cells at same offset',
  command: 'tab',
  handler: _tabInTableCellHandler,
);

final CommandShortcutEvent _backSpaceInTableCell = CommandShortcutEvent(
  key: 'Stop at the beginning of the cell',
  command: 'backspace',
  handler: _backspaceInTableCellHandler,
);

CommandShortcutEventHandler _enterInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  if (inTableNodes.isEmpty) {
    return KeyEventResult.ignored;
  }

  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final cell = inTableNodes.first.parent!;
    final nextNode = _getNextNode(inTableNodes, 0, 1);
    if (nextNode == null) {
      final transaction = editorState.transaction;
      transaction.insertNode(cell.parent!.path.next, paragraphNode());
      transaction.afterSelection =
          Selection.single(path: cell.parent!.path.next, startOffset: 0);
      editorState.apply(transaction);
    } else if (_nodeHasTextChild(nextNode)) {
      editorState.selectionService.updateSelection(
        Selection.single(
          path: nextNode.childAtIndexOrNull(0)!.path,
          startOffset: 0,
        ),
      );
    }
  }
  return KeyEventResult.handled;
};

CommandShortcutEventHandler _leftInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection) &&
      selection!.start.offset == 0) {
    final nextNode = _getNextNode(inTableNodes, -1, 0);
    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndexOrNull(0)!;
      editorState.selectionService.updateSelection(
        Selection.single(
          path: target.path,
          startOffset: target.delta!.length,
        ),
      );
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

CommandShortcutEventHandler _rightInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection) &&
      selection!.start.offset == inTableNodes.first.delta!.length) {
    final nextNode = _getNextNode(inTableNodes, 1, 0);
    if (_nodeHasTextChild(nextNode)) {
      editorState.selectionService.updateSelection(
        Selection.single(
          path: nextNode!.childAtIndexOrNull(0)!.path,
          startOffset: 0,
        ),
      );
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

CommandShortcutEventHandler _upInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final nextNode = _getNextNode(inTableNodes, 0, -1);
    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndexOrNull(0)!;
      final off = target.delta!.length > selection!.start.offset
          ? selection.start.offset
          : target.delta!.length;
      editorState.selectionService.updateSelection(
        Selection.single(path: target.path, startOffset: off),
      );
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

CommandShortcutEventHandler _downInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final nextNode = _getNextNode(inTableNodes, 0, 1);
    if (_nodeHasTextChild(nextNode)) {
      final target = nextNode!.childAtIndexOrNull(0)!;
      final off = target.delta!.length > selection!.start.offset
          ? selection.start.offset
          : target.delta!.length;
      editorState.selectionService.updateSelection(
        Selection.single(path: target.path, startOffset: off),
      );
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

CommandShortcutEventHandler _tabInTableCellHandler = (editorState) {
  final inTableNodes = _inTableNodes(editorState);
  final selection = editorState.selection;
  if (_hasSelectionAndTableCell(inTableNodes, selection)) {
    final nextNode = _getNextNode(inTableNodes, 1, 0);
    if (_nodeHasTextChild(nextNode)) {
      editorState.selectionService.updateSelection(
        Selection.single(
          path: nextNode!.childAtIndexOrNull(0)!.path,
          startOffset: 0,
        ),
      );
    }
    return KeyEventResult.handled;
  }
  return KeyEventResult.ignored;
};

CommandShortcutEventHandler _backspaceInTableCellHandler = (editorState) {
  final selection = editorState.selection;
  if (selection == null || !selection.isCollapsed) {
    return KeyEventResult.ignored;
  }

  final position = selection.start;
  final node = editorState.getNodeAtPath(position.path);
  if (node == null || node.delta == null) {
    return KeyEventResult.ignored;
  }

  if (node.parent?.type == TableCellBlockKeys.type && position.offset == 0) {
    return KeyEventResult.handled;
  }

  return KeyEventResult.ignored;
};

Iterable<Node> _inTableNodes(EditorState editorState) {
  final selection = editorState.selection;
  if (selection == null) {
    return [];
  }
  final nodes = editorState.getNodesInSelection(selection);
  return nodes.where(
    (node) => node.parent?.type.contains(TableBlockKeys.type) ?? false,
  );
}

bool _hasSelectionAndTableCell(
  Iterable<Node> nodes,
  Selection? selection,
) =>
    nodes.length == 1 &&
    selection != null &&
    selection.isCollapsed &&
    nodes.first.parent?.type == TableCellBlockKeys.type;

Node? _getNextNode(Iterable<Node> nodes, int colDiff, int rowDiff) {
  final cell = nodes.first.parent!;
  final col = cell.attributes[TableCellBlockKeys.colPosition];
  final row = cell.attributes[TableCellBlockKeys.rowPosition];
  final table = cell.parent!;

  final numCols = table.children.last.attributes['colPosition'] + 1;
  final numRows = table.children.last.attributes['rowPosition'] + 1;

  var nextCol = (col + colDiff) % numCols;
  var nextRow = row + rowDiff + ((col + colDiff) ~/ numCols);

  if (isValidPosition(nextCol, nextRow, numCols, numRows)) {
    return getCellNode(table, nextCol, nextRow);
  } else {
    return null;
  }
}

bool isValidPosition(int col, int row, int numCols, int numRows) =>
    col >= 0 && col < numCols && row >= 0 && row < numRows;

bool _nodeHasTextChild(Node? n) =>
    n != null &&
    n.children.isNotEmpty &&
    n.childAtIndexOrNull(0)!.delta != null;
