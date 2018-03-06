/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.window;

import java.awt.Color;
import java.awt.Component;
import java.io.File;
import java.util.ArrayList;
import java.util.List;
import javax.swing.DefaultComboBoxModel;
import javax.swing.JFileChooser;
import javax.swing.JOptionPane;
import testexamgenerator.dto.Answer;
import testexamgenerator.dto.Question;
import testexamgenerator.dto.Unit;
import testexamgenerator.logic.BusinessLogic;

/**
 *
 * @author pablo
 */
public class MainFrame extends javax.swing.JFrame {
    java.util.ResourceBundle bundle = java.util.ResourceBundle.getBundle("testexamgenerator/window/Bundle");
    private final String WINDOW_TITLE = bundle.getString("MainFrame.Window.Title");
    private Integer currentQuestion = 0;
    private Question editingQuestion;
    private final List<Component> questionComponents = new ArrayList<>();
    private final FormChangeListener formChangeListener;
    
    /**
     * Creates new form MainFrame
     */
    public MainFrame() {
        initComponents();
        this.setTitle(WINDOW_TITLE);
        setLocationRelativeTo(null);
        questionComponents.add(jTextAreaQuestionText);
        questionComponents.add(jButtonHtml);
        questionComponents.add(jTextFieldAnswer1);
        questionComponents.add(jTextFieldAnswer2);
        questionComponents.add(jTextFieldAnswer3);
        questionComponents.add(jTextFieldAnswer4);
        questionComponents.add(jCheckBoxAnswer1);
        questionComponents.add(jCheckBoxAnswer2);
        questionComponents.add(jCheckBoxAnswer3);
        questionComponents.add(jCheckBoxAnswer4);
        for (Component questionComponent : questionComponents)
            questionComponent.setEnabled(false);
        jButtonDeleteQuestion.setEnabled(false);
        jButtonSaveQuestion.setEnabled(false);
        jButtonNewQuestion.setEnabled(false);
        formChangeListener = new FormChangeListener(jButtonSaveQuestion);
        
    }
    
    private void refreshComboUnits()
    {
        DefaultComboBoxModel<Unit> dcm = new DefaultComboBoxModel<>();
        for (Unit unit : BusinessLogic.getUnitList())
            dcm.addElement(unit);
        jComboUnits.setModel(dcm);
        jComboUnits.setSelectedIndex(0);
        currentQuestion = 1;
        if (((Unit)jComboUnits.getSelectedItem()).getSortedQuestions()!=null)
            editingQuestion = ((Unit)jComboUnits.getSelectedItem()).getSortedQuestions().get(0);
    }

    private void updateCounters()
    {
        int totalSize = 0;
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        if (unit != null)
            totalSize = unit.getSortedQuestions().size();
        if (editingQuestion==null)
            totalSize++;
        jLabelCurrent.setText(currentQuestion.toString());
        jLabelTotal.setText(Integer.toString(totalSize));
        if (currentQuestion < totalSize)
        {
            jButtonNext.setEnabled(true);
            jButtonLast.setEnabled(true);
        }
        else
        {
            jButtonNext.setEnabled(false);
            jButtonLast.setEnabled(false);
        }
        if (currentQuestion>1)
        {
            jButtonPrevious.setEnabled(true);
            jButtonFirst.setEnabled(true);
        }
        else
        {
            jButtonPrevious.setEnabled(false);
            jButtonFirst.setEnabled(false);
        }
        
    }
    
    private void refreshQuestionList()
    {
        if (jComboUnits.getSelectedIndex()!=-1)
        {
            Unit unit = (Unit)jComboUnits.getSelectedItem();
            List<Question> listQuestions = unit.getSortedQuestions();
            if (listQuestions.size()>0)
            {
                currentQuestion=1;
                Question question = listQuestions.get(currentQuestion-1);
                loadQuestionInfo(question);
                jButtonDeleteQuestion.setEnabled(true);
            }
            else
            {
                loadQuestionInfo(null);
                currentQuestion = 0;
            }
            updateCounters();
        }
    }
    
    private void loadQuestionInfo(Question question)
    {
        if (question!=null)
        {
            jTextFieldAnswer1.getDocument().removeDocumentListener(formChangeListener);
            jTextFieldAnswer2.getDocument().removeDocumentListener(formChangeListener);
            jTextFieldAnswer3.getDocument().removeDocumentListener(formChangeListener);
            jTextFieldAnswer4.getDocument().removeDocumentListener(formChangeListener);
            jTextAreaQuestionText.getDocument().removeDocumentListener(formChangeListener);
            jCheckBoxAnswer1.removeActionListener(formChangeListener);
            jCheckBoxAnswer2.removeActionListener(formChangeListener);
            jCheckBoxAnswer3.removeActionListener(formChangeListener);
            jCheckBoxAnswer4.removeActionListener(formChangeListener);
            for (Component component : questionComponents)
                component.setEnabled(true);
            jTextAreaQuestionText.setText(question.getQuestionText());
            List<Answer> listAnswers = question.getAnswerList();
            jTextFieldAnswer1.setText(listAnswers.get(0).getAnswerText());
            jTextFieldAnswer2.setText(listAnswers.get(1).getAnswerText());
            jTextFieldAnswer3.setText(listAnswers.get(2).getAnswerText());
            jTextFieldAnswer4.setText(listAnswers.get(3).getAnswerText());
            jCheckBoxAnswer1.setSelected(listAnswers.get(0).isCorrect());
            jCheckBoxAnswer2.setSelected(listAnswers.get(1).isCorrect());
            jCheckBoxAnswer3.setSelected(listAnswers.get(2).isCorrect());
            jCheckBoxAnswer4.setSelected(listAnswers.get(3).isCorrect());
            
            jTextFieldAnswer1.getDocument().addDocumentListener(formChangeListener);
            jTextFieldAnswer2.getDocument().addDocumentListener(formChangeListener);
            jTextFieldAnswer3.getDocument().addDocumentListener(formChangeListener);
            jTextFieldAnswer4.getDocument().addDocumentListener(formChangeListener);
            jTextAreaQuestionText.getDocument().addDocumentListener(formChangeListener);
            jCheckBoxAnswer1.addActionListener(formChangeListener);
            jCheckBoxAnswer2.addActionListener(formChangeListener);
            jCheckBoxAnswer3.addActionListener(formChangeListener);
            jCheckBoxAnswer4.addActionListener(formChangeListener);
        }
        else
        {
            for (Component component : questionComponents)
                component.setEnabled(false);
            jTextAreaQuestionText.setText("");
            jTextFieldAnswer1.setText("");
            jTextFieldAnswer2.setText("");
            jTextFieldAnswer3.setText("");
            jTextFieldAnswer4.setText("");
            jCheckBoxAnswer1.setSelected(false);
            jCheckBoxAnswer2.setSelected(false);
            jCheckBoxAnswer3.setSelected(false);
            jCheckBoxAnswer4.setSelected(false);
        }
    }
    
    /**
     * This method is called from within the constructor to initialize the form.
     * WARNING: Do NOT modify this code. The content of this method is always
     * regenerated by the Form Editor.
     */
    @SuppressWarnings("unchecked")
    // <editor-fold defaultstate="collapsed" desc="Generated Code">//GEN-BEGIN:initComponents
    private void initComponents() {

        jMenuBar1 = new javax.swing.JMenuBar();
        jMenu1 = new javax.swing.JMenu();
        jMenu2 = new javax.swing.JMenu();
        jMenu6 = new javax.swing.JMenu();
        jComboUnits = new javax.swing.JComboBox();
        jLabel1 = new javax.swing.JLabel();
        jButtonAddUnit = new javax.swing.JButton();
        jPanel1 = new javax.swing.JPanel();
        jLabel2 = new javax.swing.JLabel();
        jLabel4 = new javax.swing.JLabel();
        jLabel5 = new javax.swing.JLabel();
        jLabel6 = new javax.swing.JLabel();
        jLabel7 = new javax.swing.JLabel();
        jTextFieldAnswer1 = new javax.swing.JTextField();
        jTextFieldAnswer2 = new javax.swing.JTextField();
        jTextFieldAnswer3 = new javax.swing.JTextField();
        jTextFieldAnswer4 = new javax.swing.JTextField();
        jCheckBoxAnswer3 = new javax.swing.JCheckBox();
        jCheckBoxAnswer4 = new javax.swing.JCheckBox();
        jCheckBoxAnswer1 = new javax.swing.JCheckBox();
        jCheckBoxAnswer2 = new javax.swing.JCheckBox();
        jButtonNewQuestion = new javax.swing.JButton();
        jButtonDeleteQuestion = new javax.swing.JButton();
        jButtonSaveQuestion = new javax.swing.JButton();
        jButtonHtml = new javax.swing.JButton();
        jScrollPane1 = new javax.swing.JScrollPane();
        jTextAreaQuestionText = new javax.swing.JTextArea();
        jPanelButtons = new javax.swing.JPanel();
        jButtonFirst = new javax.swing.JButton();
        jButtonPrevious = new javax.swing.JButton();
        jLabelCurrent = new javax.swing.JLabel();
        jLabel3 = new javax.swing.JLabel();
        jLabelTotal = new javax.swing.JLabel();
        jButtonNext = new javax.swing.JButton();
        jButtonLast = new javax.swing.JButton();
        jMenuBar2 = new javax.swing.JMenuBar();
        jMenu3 = new javax.swing.JMenu();
        jMenuItem1 = new javax.swing.JMenuItem();
        jMenuItemLoad = new javax.swing.JMenuItem();
        jMenuItemSaveAs = new javax.swing.JMenuItem();
        jMenu4 = new javax.swing.JMenu();
        jMenuItemGenerate = new javax.swing.JMenuItem();

        java.util.ResourceBundle bundle = java.util.ResourceBundle.getBundle("testexamgenerator/window/Bundle"); // NOI18N
        jMenu1.setText(bundle.getString("MainFrame.jMenu1.text")); // NOI18N
        jMenuBar1.add(jMenu1);

        jMenu2.setText(bundle.getString("MainFrame.jMenu2.text")); // NOI18N
        jMenuBar1.add(jMenu2);

        jMenu6.setText(bundle.getString("MainFrame.jMenu6.text")); // NOI18N

        setDefaultCloseOperation(javax.swing.WindowConstants.EXIT_ON_CLOSE);
        setMinimumSize(new java.awt.Dimension(500, 400));

        jComboUnits.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jComboUnitsActionPerformed(evt);
            }
        });

        jLabel1.setText(bundle.getString("MainFrame.jLabel1.text")); // NOI18N

        jButtonAddUnit.setText(bundle.getString("MainFrame.jButtonAddUnit.text")); // NOI18N
        jButtonAddUnit.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonAddUnitActionPerformed(evt);
            }
        });

        jPanel1.setBorder(javax.swing.BorderFactory.createLineBorder(new java.awt.Color(0, 0, 0)));

        jLabel2.setText(bundle.getString("MainFrame.jLabel2.text")); // NOI18N

        jLabel4.setText(bundle.getString("MainFrame.jLabel4.text")); // NOI18N

        jLabel5.setText(bundle.getString("MainFrame.jLabel5.text")); // NOI18N

        jLabel6.setText(bundle.getString("MainFrame.jLabel6.text")); // NOI18N

        jLabel7.setText(bundle.getString("MainFrame.jLabel7.text")); // NOI18N

        jTextFieldAnswer1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jTextFieldAnswer1ActionPerformed(evt);
            }
        });

        jCheckBoxAnswer3.setText(bundle.getString("MainFrame.jCheckBoxAnswer3.text")); // NOI18N

        jCheckBoxAnswer4.setText(bundle.getString("MainFrame.jCheckBoxAnswer4.text")); // NOI18N

        jCheckBoxAnswer1.setText(bundle.getString("MainFrame.jCheckBoxAnswer1.text")); // NOI18N

        jCheckBoxAnswer2.setText(bundle.getString("MainFrame.jCheckBoxAnswer2.text")); // NOI18N

        jButtonNewQuestion.setText(bundle.getString("MainFrame.jButtonNewQuestion.text")); // NOI18N
        jButtonNewQuestion.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonNewQuestionActionPerformed(evt);
            }
        });

        jButtonDeleteQuestion.setText(bundle.getString("MainFrame.jButtonDeleteQuestion.text")); // NOI18N
        jButtonDeleteQuestion.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonDeleteQuestionActionPerformed(evt);
            }
        });

        jButtonSaveQuestion.setText(bundle.getString("MainFrame.jButtonSaveQuestion.text")); // NOI18N
        jButtonSaveQuestion.setEnabled(false);
        jButtonSaveQuestion.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonSaveQuestionActionPerformed(evt);
            }
        });

        jButtonHtml.setText(bundle.getString("MainFrame.jButtonHtml.text")); // NOI18N
        jButtonHtml.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonHtmlActionPerformed(evt);
            }
        });

        jTextAreaQuestionText.setColumns(20);
        jTextAreaQuestionText.setRows(5);
        jScrollPane1.setViewportView(jTextAreaQuestionText);

        jPanelButtons.setLayout(new java.awt.FlowLayout(java.awt.FlowLayout.CENTER, 10, 5));

        jButtonFirst.setIcon(new javax.swing.ImageIcon(getClass().getResource("/icons/1455909222_resultset_first.png"))); // NOI18N
        jButtonFirst.setText(bundle.getString("MainFrame.jButtonFirst.text")); // NOI18N
        jButtonFirst.setEnabled(false);
        jButtonFirst.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonFirstActionPerformed(evt);
            }
        });
        jPanelButtons.add(jButtonFirst);

        jButtonPrevious.setIcon(new javax.swing.ImageIcon(getClass().getResource("/icons/1455909561_resultset_previous.png"))); // NOI18N
        jButtonPrevious.setText(bundle.getString("MainFrame.jButtonPrevious.text")); // NOI18N
        jButtonPrevious.setEnabled(false);
        jButtonPrevious.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonPreviousActionPerformed(evt);
            }
        });
        jPanelButtons.add(jButtonPrevious);

        jLabelCurrent.setFont(new java.awt.Font("Droid Sans", 0, 18)); // NOI18N
        jLabelCurrent.setText(bundle.getString("MainFrame.jLabelCurrent.text")); // NOI18N
        jPanelButtons.add(jLabelCurrent);

        jLabel3.setFont(new java.awt.Font("Droid Sans", 0, 18)); // NOI18N
        jLabel3.setText(bundle.getString("MainFrame.jLabel3.text")); // NOI18N
        jPanelButtons.add(jLabel3);

        jLabelTotal.setFont(new java.awt.Font("Droid Sans", 0, 18)); // NOI18N
        jLabelTotal.setText(bundle.getString("MainFrame.jLabelTotal.text")); // NOI18N
        jPanelButtons.add(jLabelTotal);

        jButtonNext.setIcon(new javax.swing.ImageIcon(getClass().getResource("/icons/1455909351_resultset_next.png"))); // NOI18N
        jButtonNext.setText(bundle.getString("MainFrame.jButtonNext.text")); // NOI18N
        jButtonNext.setEnabled(false);
        jButtonNext.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonNextActionPerformed(evt);
            }
        });
        jPanelButtons.add(jButtonNext);

        jButtonLast.setIcon(new javax.swing.ImageIcon(getClass().getResource("/icons/1455909445_resultset_last.png"))); // NOI18N
        jButtonLast.setText(bundle.getString("MainFrame.jButtonLast.text")); // NOI18N
        jButtonLast.setEnabled(false);
        jButtonLast.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jButtonLastActionPerformed(evt);
            }
        });
        jPanelButtons.add(jButtonLast);

        javax.swing.GroupLayout jPanel1Layout = new javax.swing.GroupLayout(jPanel1);
        jPanel1.setLayout(jPanel1Layout);
        jPanel1Layout.setHorizontalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(jPanel1Layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addGroup(jPanel1Layout.createSequentialGroup()
                                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                                    .addComponent(jLabel7)
                                    .addComponent(jLabel5)
                                    .addComponent(jLabel6)
                                    .addComponent(jLabel4))
                                .addGap(34, 34, 34))
                            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
                                .addComponent(jLabel2)
                                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)))
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jScrollPane1, javax.swing.GroupLayout.DEFAULT_SIZE, 318, Short.MAX_VALUE)
                            .addComponent(jTextFieldAnswer2)
                            .addComponent(jTextFieldAnswer4, javax.swing.GroupLayout.Alignment.TRAILING)
                            .addComponent(jTextFieldAnswer3, javax.swing.GroupLayout.Alignment.TRAILING)
                            .addComponent(jTextFieldAnswer1, javax.swing.GroupLayout.Alignment.TRAILING))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                                .addComponent(jCheckBoxAnswer1)
                                .addComponent(jCheckBoxAnswer2))
                            .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                                .addComponent(jCheckBoxAnswer3, javax.swing.GroupLayout.Alignment.TRAILING)
                                .addComponent(jCheckBoxAnswer4, javax.swing.GroupLayout.Alignment.TRAILING))
                            .addComponent(jButtonHtml, javax.swing.GroupLayout.PREFERRED_SIZE, 24, javax.swing.GroupLayout.PREFERRED_SIZE)))
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addGap(0, 0, Short.MAX_VALUE)
                        .addComponent(jButtonNewQuestion, javax.swing.GroupLayout.PREFERRED_SIZE, 136, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jButtonDeleteQuestion, javax.swing.GroupLayout.PREFERRED_SIZE, 148, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jButtonSaveQuestion, javax.swing.GroupLayout.PREFERRED_SIZE, 136, javax.swing.GroupLayout.PREFERRED_SIZE)))
                .addContainerGap())
            .addComponent(jPanelButtons, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
        );
        jPanel1Layout.setVerticalGroup(
            jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
                .addComponent(jPanelButtons, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                    .addComponent(jScrollPane1, javax.swing.GroupLayout.Alignment.TRAILING, javax.swing.GroupLayout.DEFAULT_SIZE, 56, Short.MAX_VALUE)
                    .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, jPanel1Layout.createSequentialGroup()
                        .addGap(0, 0, Short.MAX_VALUE)
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
                            .addComponent(jButtonHtml, javax.swing.GroupLayout.Alignment.TRAILING)
                            .addComponent(jLabel2, javax.swing.GroupLayout.Alignment.TRAILING))))
                .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.UNRELATED)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addGroup(jPanel1Layout.createSequentialGroup()
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jLabel4)
                            .addComponent(jTextFieldAnswer1, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(jCheckBoxAnswer1))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jTextFieldAnswer2, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(jLabel5)
                            .addComponent(jCheckBoxAnswer2))
                        .addGap(5, 5, 5)
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jTextFieldAnswer3, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(jLabel6)
                            .addComponent(jCheckBoxAnswer3))
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                            .addComponent(jTextFieldAnswer4, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                            .addComponent(jLabel7)))
                    .addComponent(jCheckBoxAnswer4))
                .addGap(18, 18, 18)
                .addGroup(jPanel1Layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jButtonNewQuestion)
                    .addComponent(jButtonSaveQuestion)
                    .addComponent(jButtonDeleteQuestion))
                .addGap(12, 12, 12))
        );

        jMenu3.setText(bundle.getString("MainFrame.jMenu3.text")); // NOI18N

        jMenuItem1.setText(bundle.getString("MainFrame.jMenuItem1.text")); // NOI18N
        jMenuItem1.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItem1ActionPerformed(evt);
            }
        });
        jMenu3.add(jMenuItem1);

        jMenuItemLoad.setText(bundle.getString("MainFrame.jMenuItemLoad.text")); // NOI18N
        jMenuItemLoad.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItemLoadActionPerformed(evt);
            }
        });
        jMenu3.add(jMenuItemLoad);

        jMenuItemSaveAs.setText(bundle.getString("MainFrame.jMenuItemSaveAs.text")); // NOI18N
        jMenuItemSaveAs.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItemSaveAsActionPerformed(evt);
            }
        });
        jMenu3.add(jMenuItemSaveAs);

        jMenuBar2.add(jMenu3);

        jMenu4.setText(bundle.getString("MainFrame.jMenu4.text")); // NOI18N

        jMenuItemGenerate.setText(bundle.getString("MainFrame.jMenuItemGenerate.text")); // NOI18N
        jMenuItemGenerate.addActionListener(new java.awt.event.ActionListener() {
            public void actionPerformed(java.awt.event.ActionEvent evt) {
                jMenuItemGenerateActionPerformed(evt);
            }
        });
        jMenu4.add(jMenuItemGenerate);

        jMenuBar2.add(jMenu4);

        setJMenuBar(jMenuBar2);

        javax.swing.GroupLayout layout = new javax.swing.GroupLayout(getContentPane());
        getContentPane().setLayout(layout);
        layout.setHorizontalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(javax.swing.GroupLayout.Alignment.TRAILING, layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.TRAILING)
                    .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                    .addGroup(layout.createSequentialGroup()
                        .addComponent(jLabel1)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jComboUnits, javax.swing.GroupLayout.PREFERRED_SIZE, 160, javax.swing.GroupLayout.PREFERRED_SIZE)
                        .addPreferredGap(javax.swing.LayoutStyle.ComponentPlacement.RELATED)
                        .addComponent(jButtonAddUnit)
                        .addGap(0, 0, Short.MAX_VALUE)))
                .addContainerGap())
        );
        layout.setVerticalGroup(
            layout.createParallelGroup(javax.swing.GroupLayout.Alignment.LEADING)
            .addGroup(layout.createSequentialGroup()
                .addContainerGap()
                .addGroup(layout.createParallelGroup(javax.swing.GroupLayout.Alignment.BASELINE)
                    .addComponent(jLabel1)
                    .addComponent(jComboUnits, javax.swing.GroupLayout.PREFERRED_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.PREFERRED_SIZE)
                    .addComponent(jButtonAddUnit))
                .addGap(12, 12, 12)
                .addComponent(jPanel1, javax.swing.GroupLayout.DEFAULT_SIZE, javax.swing.GroupLayout.DEFAULT_SIZE, Short.MAX_VALUE)
                .addContainerGap())
        );

        pack();
    }// </editor-fold>//GEN-END:initComponents

    private void jButtonAddUnitActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonAddUnitActionPerformed
        String unitName = JOptionPane.showInputDialog(this,bundle.getString("MainFrame.UnitName.Message"));
        BusinessLogic.addUnit(unitName);
        refreshComboUnits();
        newQuestion();
    }//GEN-LAST:event_jButtonAddUnitActionPerformed

    private void jComboUnitsActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jComboUnitsActionPerformed
        refreshQuestionList();
        jButtonNewQuestion.setEnabled(jComboUnits.getSelectedIndex()!=-1);
    }//GEN-LAST:event_jComboUnitsActionPerformed

    private void jButtonLastActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonLastActionPerformed
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        currentQuestion = unit.getSortedQuestions().size();
        editingQuestion=unit.getSortedQuestions().get(currentQuestion-1);
        loadQuestionInfo(editingQuestion);
        updateCounters();
    }//GEN-LAST:event_jButtonLastActionPerformed

    private void jButtonNextActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonNextActionPerformed
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        if (currentQuestion<unit.getSortedQuestions().size())
        {
            currentQuestion++;
            editingQuestion = unit.getSortedQuestions().get(currentQuestion-1);
            loadQuestionInfo(editingQuestion);
            updateCounters();
        }
    }//GEN-LAST:event_jButtonNextActionPerformed

    private void jButtonPreviousActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonPreviousActionPerformed
        if (currentQuestion>1)
        {
            currentQuestion--;
            Unit unit = (Unit)jComboUnits.getSelectedItem();
            editingQuestion = unit.getSortedQuestions().get(currentQuestion-1);
            loadQuestionInfo(editingQuestion);
            updateCounters();
        }
    }//GEN-LAST:event_jButtonPreviousActionPerformed

    private void jButtonFirstActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonFirstActionPerformed
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        editingQuestion = unit.getSortedQuestions().get(currentQuestion-1);
        loadQuestionInfo(editingQuestion);
        updateCounters();
    }//GEN-LAST:event_jButtonFirstActionPerformed

    private void jButtonHtmlActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonHtmlActionPerformed
        JDialogHtmlEditor jDialogHtmlEditor = new JDialogHtmlEditor(this, true,jTextAreaQuestionText.getText());
        jDialogHtmlEditor.setVisible(true);
    }//GEN-LAST:event_jButtonHtmlActionPerformed

    private void jButtonSaveQuestionActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonSaveQuestionActionPerformed
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        if (editingQuestion==null)
        {
            editingQuestion = new Question(jTextAreaQuestionText.getText());
            unit.addQuestion(editingQuestion,currentQuestion-1);
        }
        editingQuestion.setQuestionText(jTextAreaQuestionText.getText());
        editingQuestion.removeAnswers();
        editingQuestion.addAnswer(new Answer(jTextFieldAnswer1.getText(), jCheckBoxAnswer1.isSelected()));
        editingQuestion.addAnswer(new Answer(jTextFieldAnswer2.getText(), jCheckBoxAnswer2.isSelected()));
        editingQuestion.addAnswer(new Answer(jTextFieldAnswer3.getText(), jCheckBoxAnswer3.isSelected()));
        editingQuestion.addAnswer(new Answer(jTextFieldAnswer4.getText(), jCheckBoxAnswer4.isSelected()));

        jLabelTotal.setText(Integer.toString(unit.getSortedQuestions().size()));
        if (BusinessLogic.saveToDisk()==false)
            showSaveAsDialog();
        jButtonSaveQuestion.setBackground(null);
        jButtonSaveQuestion.setEnabled(false);
    }//GEN-LAST:event_jButtonSaveQuestionActionPerformed

    private void jButtonDeleteQuestionActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonDeleteQuestionActionPerformed
        Unit unit = (Unit)jComboUnits.getSelectedItem();
        unit.removeQuestion(currentQuestion-1);
        refreshQuestionList();
        updateCounters();
    }//GEN-LAST:event_jButtonDeleteQuestionActionPerformed

    private void newQuestion()
    {
        currentQuestion = currentQuestion+1;
        editingQuestion = null;
        jTextAreaQuestionText.setText("");
        jTextFieldAnswer1.setText("");
        jTextFieldAnswer2.setText("");
        jTextFieldAnswer3.setText("");
        jTextFieldAnswer4.setText("");
        jCheckBoxAnswer1.setSelected(false);
        jCheckBoxAnswer2.setSelected(false);
        jCheckBoxAnswer3.setSelected(false);
        jCheckBoxAnswer4.setSelected(false);
        for (Component component : questionComponents)
            component.setEnabled(true);
        jButtonSaveQuestion.setEnabled(true);
        jButtonSaveQuestion.setBackground(Color.green);
        updateCounters();
    }
    
    private void jButtonNewQuestionActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jButtonNewQuestionActionPerformed
        //Unit unit = (Unit)jComboUnits.getSelectedItem();
        //currentQuestion = unit.getSortedQuestions().size() + 1;
        newQuestion();
    }//GEN-LAST:event_jButtonNewQuestionActionPerformed

    private void jMenuItem1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItem1ActionPerformed
        // TODO add your handling code here:
    }//GEN-LAST:event_jMenuItem1ActionPerformed

    private void jMenuItemLoadActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItemLoadActionPerformed
        MyFileChooser jFileChooser = new MyFileChooser();
        if (jFileChooser.showOpenDialog(this) == JFileChooser.APPROVE_OPTION) 
        {
            File file = jFileChooser.getSelectedFile();
            if (BusinessLogic.loadFromDisk(file))
            {
                refreshComboUnits();
                //refreshQuestionList();
                updateTitle();
                updateCounters();
            }
            else
                JOptionPane.showMessageDialog(this, "MainFrame.Load.ErrorMessage");
        }
    }//GEN-LAST:event_jMenuItemLoadActionPerformed

    private void jMenuItemSaveAsActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItemSaveAsActionPerformed
        showSaveAsDialog();
    }//GEN-LAST:event_jMenuItemSaveAsActionPerformed

    private void jMenuItemGenerateActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jMenuItemGenerateActionPerformed
        JDialogGenerateExam jDialogNew = new JDialogGenerateExam(this,true);
        jDialogNew.setVisible(true);
    }//GEN-LAST:event_jMenuItemGenerateActionPerformed

    private void jTextFieldAnswer1ActionPerformed(java.awt.event.ActionEvent evt) {//GEN-FIRST:event_jTextFieldAnswer1ActionPerformed
    }//GEN-LAST:event_jTextFieldAnswer1ActionPerformed

    public void setQuestionText(String text)
    {
        this.jTextAreaQuestionText.setText(text);
    }
    
    private void showSaveAsDialog()
    {
        MyFileChooser fileChooser = new MyFileChooser();
        if (fileChooser.showSaveDialog(this) == JFileChooser.APPROVE_OPTION) {
            File file = fileChooser.getSelectedFile();
            if (!file.exists() && !file.getName().endsWith(".xml"))
                file = new File(file.getAbsolutePath()+".xml");
            if (BusinessLogic.saveToDiskAs(file))
                updateTitle();
            else
                JOptionPane.showMessageDialog(this, "Error while saving file to disk");
        }
    }
    
    private void updateTitle()
    {
        this.setTitle(WINDOW_TITLE + " - " + BusinessLogic.getCurrentFileName());
    }
    /**
     * @param args the command line arguments
     */
    public static void main(String args[]) {
        /* Set the Nimbus look and feel */
        //<editor-fold defaultstate="collapsed" desc=" Look and feel setting code (optional) ">
        /* If Nimbus (introduced in Java SE 6) is not available, stay with the default look and feel.
         * For details see http://download.oracle.com/javase/tutorial/uiswing/lookandfeel/plaf.html 
         */
        try {
            for (javax.swing.UIManager.LookAndFeelInfo info : javax.swing.UIManager.getInstalledLookAndFeels()) {
                if ("Nimbus".equals(info.getName())) {
                    javax.swing.UIManager.setLookAndFeel(info.getClassName());
                    break;
                }
            }
        } catch (ClassNotFoundException | InstantiationException | IllegalAccessException | javax.swing.UnsupportedLookAndFeelException ex) {
            java.util.logging.Logger.getLogger(MainFrame.class.getName()).log(java.util.logging.Level.SEVERE, null, ex);
        }
        //</editor-fold>
        
        //</editor-fold>

        /* Create and display the form */
        java.awt.EventQueue.invokeLater(new Runnable() {
            @Override
            public void run() {
                new MainFrame().setVisible(true);
            }
        });
    }

    // Variables declaration - do not modify//GEN-BEGIN:variables
    private javax.swing.JButton jButtonAddUnit;
    private javax.swing.JButton jButtonDeleteQuestion;
    private javax.swing.JButton jButtonFirst;
    private javax.swing.JButton jButtonHtml;
    private javax.swing.JButton jButtonLast;
    private javax.swing.JButton jButtonNewQuestion;
    private javax.swing.JButton jButtonNext;
    private javax.swing.JButton jButtonPrevious;
    private javax.swing.JButton jButtonSaveQuestion;
    private javax.swing.JCheckBox jCheckBoxAnswer1;
    private javax.swing.JCheckBox jCheckBoxAnswer2;
    private javax.swing.JCheckBox jCheckBoxAnswer3;
    private javax.swing.JCheckBox jCheckBoxAnswer4;
    private javax.swing.JComboBox jComboUnits;
    private javax.swing.JLabel jLabel1;
    private javax.swing.JLabel jLabel2;
    private javax.swing.JLabel jLabel3;
    private javax.swing.JLabel jLabel4;
    private javax.swing.JLabel jLabel5;
    private javax.swing.JLabel jLabel6;
    private javax.swing.JLabel jLabel7;
    private javax.swing.JLabel jLabelCurrent;
    private javax.swing.JLabel jLabelTotal;
    private javax.swing.JMenu jMenu1;
    private javax.swing.JMenu jMenu2;
    private javax.swing.JMenu jMenu3;
    private javax.swing.JMenu jMenu4;
    private javax.swing.JMenu jMenu6;
    private javax.swing.JMenuBar jMenuBar1;
    private javax.swing.JMenuBar jMenuBar2;
    private javax.swing.JMenuItem jMenuItem1;
    private javax.swing.JMenuItem jMenuItemGenerate;
    private javax.swing.JMenuItem jMenuItemLoad;
    private javax.swing.JMenuItem jMenuItemSaveAs;
    private javax.swing.JPanel jPanel1;
    private javax.swing.JPanel jPanelButtons;
    private javax.swing.JScrollPane jScrollPane1;
    private javax.swing.JTextArea jTextAreaQuestionText;
    private javax.swing.JTextField jTextFieldAnswer1;
    private javax.swing.JTextField jTextFieldAnswer2;
    private javax.swing.JTextField jTextFieldAnswer3;
    private javax.swing.JTextField jTextFieldAnswer4;
    // End of variables declaration//GEN-END:variables
}
