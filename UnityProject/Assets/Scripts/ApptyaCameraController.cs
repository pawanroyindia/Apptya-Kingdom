using UnityEngine;
using UnityEngine.EventSystems;

namespace ApptyaKingdom
{
    /// <summary>Basic mobile-friendly orbit and pinch-zoom controls for the kingdom view.</summary>
    public class ApptyaCameraController : MonoBehaviour
    {
        [SerializeField] float dragSensitivity = 0.18f;
        [SerializeField] float zoomSensitivity = 0.025f;
        [SerializeField] float minDistance = 12f;
        [SerializeField] float maxDistance = 34f;
        [SerializeField] float minPitch = 22f;
        [SerializeField] float maxPitch = 58f;

        Vector3 focus = new Vector3(0f, 0f, 1f);
        float yaw;
        float pitch = 32f;
        float distance = 27f;
        Vector2 previousTouch;
        bool wasDragging;
        bool touchStartedOverUI;
        bool pinchBlockedByUI;

        void Start()
        {
            Vector3 offset = transform.position - focus;
            distance = Mathf.Clamp(offset.magnitude, minDistance, maxDistance);
            if (offset.sqrMagnitude > 0.01f)
            {
                yaw = Mathf.Atan2(offset.x, offset.z) * Mathf.Rad2Deg;
                pitch = Mathf.Clamp(Mathf.Atan2(offset.y, new Vector2(offset.x, offset.z).magnitude) * Mathf.Rad2Deg, minPitch, maxPitch);
            }
            ApplyCamera();
        }

        void LateUpdate()
        {
            if (Input.touchCount == 2)
            {
                wasDragging = false;
                Touch a = Input.GetTouch(0);
                Touch b = Input.GetTouch(1);
                // Do not zoom the world while a two-finger gesture is interacting with HUD controls.
                if (EventSystem.current != null &&
                    (EventSystem.current.IsPointerOverGameObject(a.fingerId) ||
                     EventSystem.current.IsPointerOverGameObject(b.fingerId)))
                    pinchBlockedByUI = true;
                if (pinchBlockedByUI) return;
                Vector2 aPrev = a.position - a.deltaPosition;
                Vector2 bPrev = b.position - b.deltaPosition;
                float previousGap = Vector2.Distance(aPrev, bPrev);
                float currentGap = Vector2.Distance(a.position, b.position);
                distance = Mathf.Clamp(distance - (currentGap - previousGap) * zoomSensitivity, minDistance, maxDistance);
                ApplyCamera();
                return;
            }

            if (Input.touchCount == 1)
            {
                Touch t = Input.GetTouch(0);
                if (t.phase == TouchPhase.Began)
                {
                    previousTouch = t.position;
                    touchStartedOverUI = EventSystem.current != null && EventSystem.current.IsPointerOverGameObject(t.fingerId);
                }
                else if (t.phase == TouchPhase.Moved && !touchStartedOverUI && !pinchBlockedByUI)
                {
                    Vector2 delta = t.position - previousTouch;
                    yaw += delta.x * dragSensitivity;
                    pitch = Mathf.Clamp(pitch - delta.y * dragSensitivity, minPitch, maxPitch);
                    previousTouch = t.position;
                    ApplyCamera();
                }
                return;
            }
            touchStartedOverUI = false;
            pinchBlockedByUI = false;

            // Mouse fallback makes the camera easy to test in the Unity Editor.
            if (Input.GetMouseButtonDown(0))
            {
                previousTouch = Input.mousePosition;
                wasDragging = EventSystem.current == null || !EventSystem.current.IsPointerOverGameObject();
            }
            if (Input.GetMouseButton(0) && wasDragging)
            {
                Vector2 current = Input.mousePosition;
                Vector2 delta = current - previousTouch;
                yaw += delta.x * dragSensitivity;
                pitch = Mathf.Clamp(pitch - delta.y * dragSensitivity, minPitch, maxPitch);
                previousTouch = current;
                ApplyCamera();
            }
            if (Input.GetMouseButtonUp(0)) wasDragging = false;
            float scroll = Input.mouseScrollDelta.y;
            bool mouseOverUI = EventSystem.current != null && EventSystem.current.IsPointerOverGameObject();
            if (!mouseOverUI && Mathf.Abs(scroll) > 0.01f)
            {
                distance = Mathf.Clamp(distance - scroll, minDistance, maxDistance);
                ApplyCamera();
            }
        }

        void ApplyCamera()
        {
            Quaternion rotation = Quaternion.Euler(pitch, yaw, 0f);
            transform.position = focus + rotation * new Vector3(0f, 0f, -distance);
            transform.rotation = rotation;
        }
    }
}