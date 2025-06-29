module testing;
import dgui;

class TestPanel : Panel {
	this() {
		border = 32;

		gap = 10;

		auto test_panel1 = new Panel(this);
		test_panel1.width = 100;
		test_panel1.height = 100;

		auto test_panel2 = new Panel(this);
		test_panel2.width = 100;
		test_panel2.height = 100;
	}

	override void PerformLayout() {
		PositionChildren();
	}
}
