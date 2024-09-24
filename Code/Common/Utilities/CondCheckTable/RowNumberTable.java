import java.io.*;
import java.awt.*;
import java.awt.event.*;
import java.beans.*;
import javax.swing.*;
import javax.swing.event.*;
import javax.swing.table.*;

/*
 *	Use a JTable as a renderer for row numbers of a given main table.
 *  This table must be added to the row header of the scrollpane that
 *  contains the main table.
 */
public class RowNumberTable extends JTable
	implements ChangeListener, PropertyChangeListener, TableModelListener
{
	private JTable main;
	private static int rowOfs;

	public RowNumberTable(JTable table, int Type)
	{
		rowOfs = 0;		
		main = table;        
		
		main.addPropertyChangeListener( this );
		main.getModel().addTableModelListener( this );
                
		setFocusable( false );
		setAutoCreateColumnsFromModel( false );
		setSelectionModel( main.getSelectionModel() );

		TableColumn column = new TableColumn();
		column.setHeaderValue(" ");
		addColumn( column );
		column.setCellRenderer(new RowNumberRenderer(Type));

		getColumnModel().getColumn(0).setPreferredWidth(50);
		setPreferredScrollableViewportSize(getPreferredSize());
        getTableHeader().setDefaultRenderer(new RowHeaderRenderer());
        getTableHeader().setReorderingAllowed(false);
	}
	
	public void setRowOffsetCount(int rOfs)
	{
		rowOfs = rOfs;
	}

	@Override
	public void addNotify()
	{
		super.addNotify();

		Component c = getParent();

		//  Keep scrolling of the row table in sync with the main table.

		if (c instanceof JViewport)
		{
			JViewport viewport = (JViewport)c;
			viewport.addChangeListener( this );
		}
	}

	/*
	 *  Delegate method to main table
	 */
	@Override
	public int getRowCount()
	{
		return main.getRowCount();
	}

	@Override
	public int getRowHeight(int row)
	{
		int rowHeight = main.getRowHeight(row);

		if (rowHeight != super.getRowHeight(row))
		{
			super.setRowHeight(row, rowHeight);
		}

		return rowHeight;
	}

	/*
	 *  No model is being used for this table so just use the row number
	 *  as the value of the cell.
	 */
	@Override
	public Object getValueAt(int row, int column)
	{
		return Integer.toString(rowOfs + row + 1);
	}

	/*
	 *  Don't edit data in the main TableModel by mistake
	 */
	@Override
	public boolean isCellEditable(int row, int column)
	{
		return false;
	}

	/*
	 *  Do nothing since the table ignores the model
	 */
	@Override
	public void setValueAt(Object value, int row, int column) {}
//
//  Implement the ChangeListener
//
	public void stateChanged(ChangeEvent e)
	{
		//  Keep the scrolling of the row table in sync with main table

		JViewport viewport = (JViewport) e.getSource();
		JScrollPane scrollPane = (JScrollPane)viewport.getParent();
		scrollPane.getVerticalScrollBar().setValue(viewport.getViewPosition().y);
	}
//
//  Implement the PropertyChangeListener
//
	public void propertyChange(PropertyChangeEvent e)
	{
		//  Keep the row table in sync with the main table

		if ("selectionModel".equals(e.getPropertyName()))
		{
			setSelectionModel( main.getSelectionModel() );
		}

		if ("rowHeight".equals(e.getPropertyName()))
		{
			repaint();
		}

		if ("model".equals(e.getPropertyName()))
		{
			main.getModel().addTableModelListener( this );
			revalidate();
		}
	}

//
//  Implement the TableModelListener
//
	@Override
	public void tableChanged(TableModelEvent e)
	{
		revalidate();
	}

	/*
	 *  Attempt to mimic the table header renderer
	 */
	private static class RowNumberRenderer extends DefaultTableCellRenderer
	{
        private int tType;
        private int nCol;
        private String typeStr;
        
		public RowNumberRenderer(int Type)
		{       
            tType = 0;
            
            if (Type < 0) {
                nCol = -Type;
                tType = 1;                
            } else if (Type == 0) {
                typeStr = "Fly #";
            } else if (Type == 1) {
                typeStr = "Row #";                
            } else {
				typeStr = "#";
            }
            
			setHorizontalAlignment(JLabel.CENTER);
		}

		public Component getTableCellRendererComponent(
			JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int column)
		{
			if (table != null)
			{
				JTableHeader header = table.getTableHeader();

				if (header != null)
				{
					setForeground(header.getForeground());
					setBackground(header.getBackground());
					setFont(header.getFont());
				}
			}          
            
			setFont(new Font("Segoe UI", Font.PLAIN, 12));
            
            if (tType == 1)
            {
                int valueI = Integer.parseInt(value.toString());
                int iRow = ((valueI - 1) / nCol) + 1;
                int iCol = ((valueI - 1) % nCol) + 1;
    			setText((value == null) ? "" : "R" + 
                      Integer.toString(iRow) + "/C" + Integer.toString(iCol));                
                
            } else {
    			setText((value == null) ? "" : typeStr + (String) value.toString());
            }

			return this;
		}
	}
    
    private static class RowHeaderRenderer extends JLabel implements TableCellRenderer {

        public RowHeaderRenderer() {
            setBorder(BorderFactory.createEtchedBorder());
        }
        
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                boolean isSelected, boolean hasFocus, int row, int column) {
            setText(value.toString());
            return this;
        }        
    }        
}
