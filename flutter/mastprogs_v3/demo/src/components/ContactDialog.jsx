import { CONTACT } from "../content/resume.js";
import { Modal } from "./Modal.jsx";
import { ContactSlots } from "./resume/ContactSlots.jsx";

export function ContactDialog({ open, onClose }) {
  return (
    <Modal open={open} onClose={onClose} labelledBy="contact-dialog-title" className="contact-dialog" closeLabel="연락처 닫기">
      <div className="contact-detail">
        <h2 id="contact-dialog-title" className="contact-detail__title">{CONTACT.heading}</h2>
        <ContactSlots showHeading={false} className="contact-slots--dialog" />
      </div>
    </Modal>
  );
}
