/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package testexamgenerator.window;

import java.awt.Color;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import javax.swing.JButton;
import javax.swing.event.DocumentEvent;
import javax.swing.event.DocumentListener;

/**
 *
 * @author pablo
 */
public class FormChangeListener implements DocumentListener, ActionListener{
    private JButton buttonToEnable;
    
    public FormChangeListener(JButton buttonToEnable)
    {
        this.buttonToEnable = buttonToEnable;
    }

    private void enableButton()
    {
        buttonToEnable.setEnabled(true);
        buttonToEnable.setBackground(Color.green);
    }
    
    @Override
    public void insertUpdate(DocumentEvent e) {
        enableButton();
    }

    @Override
    public void removeUpdate(DocumentEvent e) {
        enableButton();
    }

    @Override
    public void changedUpdate(DocumentEvent e) {
        
    }

    @Override
    public void actionPerformed(ActionEvent e) {
        enableButton();
    }
}
