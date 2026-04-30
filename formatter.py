from Presenter import DefaultPresenter, Presenter, PresenterFormat, PresenterLine, PresenterOutput, SegmentType
from MemorySegment import MemorySegment
from Symbols import SymbolTable
from Machine import Machine

class ActionQueuePresenter(Presenter):
    format = [PresenterFormat(SegmentType.ADDRESS, 6), PresenterFormat(SegmentType.DATA), PresenterFormat(SegmentType.TEXT)]
    brief_format = [PresenterFormat(SegmentType.DATA), PresenterFormat(SegmentType.TEXT)]

    def __init__(self, symbols: SymbolTable, machine: Machine):
        super().__init__(symbols, machine)

    def present(self, data: MemorySegment, max_lines: int|None = None, brief: bool = False) -> PresenterOutput:
        fill_symbol = self.symbols["bottom_actions_fill"]
        fill_memory = self.machine.get_memory(fill_symbol.address, fill_symbol.size)
        fill = fill_memory[0]
        actions = []

        hex_values = " ".join(f"{byte:02x}" for byte in data[0:data.size or fill])
        address = data.address
        while fill > 0 and not data.is_empty():
            action_address = data.get_int(2)
            fill -= 2
            actions.append(self.symbols.symbolize_address(action_address))

        string = ", ".join(actions)
        if brief:
            return PresenterOutput([PresenterLine([hex_values, string])], [PresenterFormat(SegmentType.DATA), PresenterFormat(SegmentType.TEXT)])
        else:
            return PresenterOutput([PresenterLine([f".{address:04x}:", hex_values, string])], [PresenterFormat(SegmentType.ADDRESS), PresenterFormat(SegmentType.DATA), PresenterFormat(SegmentType.TEXT)])


def register(presenter: DefaultPresenter):
    presenter.register_presenter("action_queue", ActionQueuePresenter)
    presenter.register_symbol_presenter("bottom_actions", "action_queue")
