import java.awt.Color;
import java.awt.Component;
import java.awt.Dimension;
import java.awt.Graphics;
import java.awt.Font;
import java.awt.FontMetrics;
import java.awt.GridBagLayout;
import java.awt.GridLayout;
import java.awt.Insets;
import java.awt.Rectangle;

import javax.swing.BorderFactory;
import javax.swing.ListSelectionModel;
import javax.swing.JCheckBox;
import javax.swing.JComponent;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.JTable;
import javax.swing.table.DefaultTableModel;
import javax.swing.table.DefaultTableCellRenderer;
import javax.swing.table.JTableHeader;
import javax.swing.table.TableCellRenderer;

public class CondCheckTable extends JTable {

    private static int cType;    
    private static Object[][] bgCol;
    private static ConditionalStringRenderer crD;
    private static ConditionalCheckBoxRenderer crC;
    private static ListSelectionModel lsm;
    private static TableCellRenderer cr;
    private static Font tFont = new Font("Segoe UI", Font.PLAIN, 12);
    
	public CondCheckTable(DefaultTableModel model, int type, Object[][] _bgCol) {
        // table construction
        super();
        cType = type;
        setModel(model);               
                
        // other initialisations
        crD = new ConditionalStringRenderer();
        crC = new ConditionalCheckBoxRenderer(); 
        lsm = this.getSelectionModel();  
        
        if (cType == 1) {
            crC.SetBGColour(_bgCol);
            cr = crC;
            
        } else {
            crC.SetBGColour(_bgCol);
            cr = crD;
        }
                
        // retrieves the height dimensions of the cells          
        int nCols = this.getColumnCount();
        
        //Sets the cell renderer for each column        
        for (int iCol = 0; iCol < nCols; iCol = iCol + 1) { 
            getColumnModel().getColumn(iCol).setCellRenderer(cr);
        }           
        
        // sets the selection mode        
        setSelectionMode(lsm.SINGLE_SELECTION);
        setCellSelectionEnabled(true);                                          
                        
//         // centers the table headers
//         TableCellRenderer rHeader = this.getTableHeader().getDefaultRenderer();
//         JLabel hLabel = (JLabel) rHeader;
//         hLabel.setHorizontalAlignment(JLabel.CENTER);
        
        // resizes the table to fit the entire table
        getTableHeader().setFont(tFont);
        getTableHeader().setReorderingAllowed(false);        
        getTableHeader().setDefaultRenderer(new ConditionalHeaderRenderer());
        setFillsViewportHeight(true);
    }
    
    public void SetBGColour(Object[][] _bgCol) {
        
        if (cType == 1) {
            crC.SetBGColour(_bgCol);
        } else {
            crD.SetBGColour(_bgCol);
        }
        
    }
    
    public void SetBGColourCell(int row, int col, Object _bgCol) {
        
        if (cType == 1) {
            crC.SetBGColourCell(row, col, _bgCol);
        } else {
            crD.SetBGColourCell(row, col, _bgCol);
        }
        
    }    
    
    public CondCheckTable(DefaultTableModel model, int type) {
        
        this(model, type, null);
    }
    
    @Override
    public Class getColumnClass(int column) {     
        if (cType == 1) {
            return Boolean.class;
        } else {
            return String.class;
        }
    }     

    @Override
    public boolean isCellEditable(int row, int column) {
        // retrieves the current value        
        if (cType == 1) {
            Object value = getValueAt(row, column);
            return !(value == null);
        } else {
            return false;
        }
    }       
    
    public static class ConditionalStringRenderer extends DefaultTableCellRenderer implements TableCellRenderer {    
        
        private static Object[][] bgCol;
        
        public ConditionalStringRenderer() {                                       
            super();                             
        }            
        
        @Override
        public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int col) 
        {   
            // initialisation
            JComponent cell = (JComponent) super.getTableCellRendererComponent(table, value, isSelected, hasFocus, row, col);                        
            if (value == null) {
                cell.setBackground(Color.GRAY);
                cell.setOpaque(true);
            } else {
                setHorizontalAlignment(JLabel.CENTER);
                cell.setForeground(Color.BLACK);
                cell.setBackground(GetBGColourCell(row, col));
            }                                                            
            return cell;
        }    
        
        public void SetBGColour(Object[][] _bgCol) {
            
            bgCol = _bgCol;
            
        }
        
        public void SetBGColourCell(int row, int col, Object _bgCol) {
            
            bgCol[row][col] = _bgCol;
            
        }   
        
        public Color GetBGColourCell(int row, int col) {
            
            if (bgCol == null) {
                return Color.WHITE;
            } else {
                return (Color) bgCol[row][col];
            }
            
        }        
    }
    
    public static class ConditionalCheckBoxRenderer extends JPanel implements TableCellRenderer {

        private JCheckBox cb;
        private static Object[][] bgCol;

        public ConditionalCheckBoxRenderer() {                                       
            setLayout(new GridBagLayout());    
            setOpaque(true);                                
            cb = new JCheckBox();
            cb.setOpaque(false);
            cb.setContentAreaFilled(true);            
            add(cb);
        }              

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value, boolean isSelected, boolean hasFocus, int row, int col) {                                                
            //setOpaque(isSelected);
            if (value == null) {
                cb.setVisible(false);
                cb.setContentAreaFilled(true);
                setBackground(Color.GRAY);
                setOpaque(true);
            } else {
                //cb.setOpaque(false);
                cb.setVisible(true);
                cb.setSelected((boolean)value);     
                cb.setMargin(new Insets(-1, 0, -1, 0));
                setOpaque(true);

                if (isSelected) {
                    setForeground(table.getSelectionForeground());                   
                    setBackground(GetBGColourCell(row, col));
                    
                } else {
                    setForeground(table.getForeground());
                    setBackground(GetBGColourCell(row, col));
                }                     
            }                                                            
            return this;
        }
        
        public void SetBGColour(Object[][] _bgCol) {
            
            bgCol = _bgCol;
            
        }
        
        public void SetBGColourCell(int row, int col, Object _bgCol) {
            
            bgCol[row][col] = _bgCol;
            
        }   
        
        public Color GetBGColourCell(int row, int col) {
            
            if (bgCol == null) {
                return Color.WHITE;
            } else {
                return (Color) bgCol[row][col];
            }
            
        }        
    }                  
    
    public class ConditionalHeaderRenderer extends JLabel implements TableCellRenderer {

        public ConditionalHeaderRenderer() {
            setFont(tFont);
            setBorder(BorderFactory.createEtchedBorder());
            setHorizontalAlignment(JLabel.CENTER);
        }

        @Override
        public Component getTableCellRendererComponent(JTable table, Object value,
                boolean isSelected, boolean hasFocus, int row, int column) {
            setText(value.toString());
            return this;
        }
    }    
}